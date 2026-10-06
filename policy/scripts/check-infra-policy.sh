#!/usr/bin/env bash
# Pemeriksaan kebijakan infrastruktur & Laravel/Bootstrap (tanpa tool eksternal) untuk gate pipeline.
# Ancaman TM v1: T-02 (SQLi), T-05 (DB terekspos), T-06 (secret), T-07 (debug/verbose error),
#                T-10 (container root), T-11 (aset CDN tanpa SRI).
# Pemakaian (dari root repo Laravel): bash policy/scripts/check-infra-policy.sh [docker-compose.yml]
set -uo pipefail

COMPOSE="${1:-docker-compose.yml}"
FAIL=0
fail() { echo "::error::[POLICY FAIL] $1"; FAIL=1; }
ok()   { echo "[OK] $1"; }
warn() { echo "::warning::$1"; }

# ---------------------------------------------------------------- Docker Compose
if [[ -f "$COMPOSE" ]]; then
  # T-05: service database tidak boleh mem-publish ports ke host
  if python3 - "$COMPOSE" <<'PY'
import sys, yaml
data = yaml.safe_load(open(sys.argv[1])) or {}
bad = []
for name, svc in (data.get("services") or {}).items():
    image = str(svc.get("image", "")).lower()
    if ("postgres" in name.lower() or "postgres" in image or name.lower() == "db") and svc.get("ports"):
        bad.append(name)
sys.exit(1 if bad else 0)
PY
  then ok "T-05: service database tidak mem-publish port ke host"
  else fail "T-05: service database mem-publish 'ports' ke host. Hapus 'ports' dan pakai jaringan internal saja"
  fi

  # T-06: tidak ada password/APP_KEY literal di compose
  if grep -Eiq '(POSTGRES_PASSWORD|DB_PASSWORD|APP_KEY)\s*[:=]\s*["'"'"']?[A-Za-z0-9]' "$COMPOSE" \
     && ! grep -Eiq '(POSTGRES_PASSWORD|DB_PASSWORD|APP_KEY)\s*[:=]\s*["'"'"']?\$\{' "$COMPOSE"; then
    fail "T-06: password/APP_KEY ter-hardcode di $COMPOSE. Gunakan \${VAR} dari env/secret"
  else
    ok "T-06: tidak ada password/APP_KEY literal di $COMPOSE"
  fi

  # T-07: APP_DEBUG=true tidak boleh di compose (dianggap konfigurasi deploy)
  if grep -Eiq 'APP_DEBUG\s*[:=]\s*["'"'"']?true' "$COMPOSE"; then
    fail "T-07: APP_DEBUG=true di $COMPOSE. Produksi wajib APP_DEBUG=false"
  else
    ok "T-07: APP_DEBUG tidak aktif di $COMPOSE"
  fi
else
  warn "$COMPOSE belum ada, pemeriksaan compose dilewati"
fi

# ---------------------------------------------------------------- Dockerfile
# T-10: setiap Dockerfile wajib berakhir dengan USER non-root; T-07: tidak boleh APP_DEBUG=true
mapfile -t DOCKERFILES < <(find . -type f \( -name 'Dockerfile' -o -name 'Dockerfile.*' \) -not -path './vendor/*' -not -path './node_modules/*')
[[ ${#DOCKERFILES[@]} -eq 0 ]] && warn "Belum ada Dockerfile, pemeriksaan USER dilewati"
for f in "${DOCKERFILES[@]}"; do
  last_user=$(grep -Ei '^\s*USER\s+' "$f" | tail -n1 | awk '{print $2}')
  if [[ -z "$last_user" || "$last_user" == "root" || "$last_user" == "0" ]]; then
    fail "T-10: $f tidak menjalankan container sebagai non-root (mis. 'USER www-data')"
  else
    ok "T-10: $f memakai USER $last_user"
  fi
  if grep -Eiq 'APP_DEBUG\s*=\s*true' "$f"; then
    fail "T-07: APP_DEBUG=true di $f"
  fi
done

# ---------------------------------------------------------------- Laravel: secret & konfigurasi
# T-06: file .env asli tidak boleh ter-track git
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git ls-files --error-unmatch .env >/dev/null 2>&1; then
    fail "T-06: file .env ter-track di Git. Jalankan 'git rm --cached .env', tambahkan ke .gitignore, dan ROTASI kredensial"
  else
    ok "T-06: .env tidak ter-track di Git"
  fi
fi

# T-07: file env produksi tidak boleh APP_DEBUG=true
for f in .env.production .env.prod .env.production.example; do
  if [[ -f "$f" ]] && grep -Eiq '^\s*APP_DEBUG\s*=\s*true' "$f"; then
    fail "T-07: APP_DEBUG=true di $f"
  fi
done

# ---------------------------------------------------------------- Laravel: guard raw query (T-02)
# SonarQube Community tidak memiliki taint analysis SQLi, jadi pola berbahaya dicegat di sini.
# Menandai raw query yang menyambung/menginterpolasi variabel (bukan memakai binding '?').
if [[ -d app || -d routes ]]; then
  hits=$(grep -RInE --include='*.php' \
    '(DB::(select|statement|unprepared|raw|insert|update|delete)|whereRaw|selectRaw|orderByRaw|havingRaw|groupByRaw|fromRaw|joinRaw)\s*\(\s*("[^"]*\$|'"'"'[^'"'"']*'"'"'\s*\.\s*\$|"[^"]*"\s*\.\s*\$)' \
    app routes 2>/dev/null || true)
  if [[ -n "$hits" ]]; then
    echo "$hits"
    fail "T-02: raw query dengan interpolasi/konkatenasi variabel. Gunakan binding parameter (?) atau Query Builder/Eloquent"
  else
    ok "T-02: tidak ada raw query dengan interpolasi variabel di app/ dan routes/"
  fi
fi

# ---------------------------------------------------------------- Frontend Bootstrap: SRI untuk aset CDN (T-11)
python3 - <<'PY'
import re, sys, pathlib
ALLOW = ("fonts.googleapis.com", "fonts.gstatic.com")  # tidak mendukung SRI
tag = re.compile(r'<(script|link)\b([^>]*)>', re.I | re.S)
bad = []
roots = [p for p in ("resources/views", "public") if pathlib.Path(p).exists()]
for root in roots:
    for path in pathlib.Path(root).rglob("*"):
        if path.suffix not in (".php", ".html", ".htm") or "vendor" in path.parts:
            continue
        text = path.read_text(errors="ignore")
        for m in tag.finditer(text):
            kind, attrs = m.group(1).lower(), m.group(2)
            url = re.search(r'(?:src|href)\s*=\s*["\'](https?://[^"\']+)', attrs, re.I)
            if not url:
                continue
            if kind == "link" and not re.search(r'rel\s*=\s*["\']stylesheet', attrs, re.I):
                continue
            if any(d in url.group(1) for d in ALLOW):
                continue
            if not re.search(r'\bintegrity\s*=', attrs, re.I):
                bad.append(f"{path}: {url.group(1)}")
for b in bad:
    print(b)
if bad:
    print("::error::[POLICY FAIL] T-11: aset CDN tanpa atribut integrity (SRI). Tambahkan integrity + crossorigin=\"anonymous\" atau host aset secara lokal")
    sys.exit(1)
print("[OK] T-11: semua aset CDN memakai SRI (atau tidak ada aset CDN)")
PY
[[ $? -ne 0 ]] && FAIL=1

exit $FAIL