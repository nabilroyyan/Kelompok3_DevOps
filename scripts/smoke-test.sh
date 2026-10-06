#!/usr/bin/env bash
# =============================================================================
# Axon DSS — uji asap & pemeriksaan kepatuhan kebijakan (peran Infra)
#
# Skrip ini menjawab satu pertanyaan: "apakah deployment benar-benar memenuhi
# kebijakan Security Engineer?" Setiap pemeriksaan mencantumkan kode kontrol
# (TLS-x / EXP-x / T-xx) agar hasilnya bisa langsung dipakai sebagai bukti.
#
# Pemakaian:
#   bash scripts/smoke-test.sh [https://host] [http://host]
#   GATE=1 bash scripts/smoke-test.sh    # + jalankan skrip Security
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"

HTTPS_BASE="${1:-https://localhost}"
HTTP_BASE="${2:-http://localhost}"

# -k diperlukan karena sertifikat development bersifat self-signed (TLS-5).
CURL=(curl -sS -k --max-time 10)

PASS_N=0
FAIL_N=0

pass() { PASS_N=$((PASS_N + 1)); echo "  [PASS] $1"; }
bad()  { FAIL_N=$((FAIL_N + 1)); echo "  [FAIL] $1"; }
info() { echo "  [INFO] $1"; }

code() { "${CURL[@]}" -o /dev/null -w '%{http_code}' "$1" 2>/dev/null || echo "000"; }

echo "== Smoke test Axon DSS =="
echo "HTTPS : ${HTTPS_BASE}"
echo "HTTP  : ${HTTP_BASE}"
echo

# --- Status container --------------------------------------------------------
echo "-- Status container (Tugas 1) --"
docker compose -f "${COMPOSE_FILE}" ps

# --- TLS: redirect HTTP -> HTTPS (TLS-2) ------------------------------------
echo "-- TLS --"
rc="$(code "${HTTP_BASE}/")"
if [[ "${rc}" =~ ^30[18]$ ]]; then
    pass "TLS-2 ${HTTP_BASE} dialihkan permanen ke HTTPS (status ${rc})"
else
    bad "TLS-2 ${HTTP_BASE} tidak mengembalikan 301/308 (status ${rc})"
fi

hsts="$("${CURL[@]}" -I "${HTTPS_BASE}/" 2>/dev/null | tr -d '\r' | grep -i '^Strict-Transport-Security:')"
if [[ -n "${hsts}" ]]; then
    pass "TLS-3 HSTS terkirim: ${hsts#*: }"
else
    bad "TLS-3 header Strict-Transport-Security tidak ditemukan"
fi

# --- Header keamanan (EXP) --------------------------------------------------
echo "-- Header keamanan (02-exposure-control 2.3) --"
hdrs="$("${CURL[@]}" -I "${HTTPS_BASE}/" 2>/dev/null | tr -d '\r')"
for h in X-Content-Type-Options X-Frame-Options Referrer-Policy Permissions-Policy Content-Security-Policy; do
    if grep -qi "^${h}:" <<<"${hdrs}"; then
        pass "Header ${h} terkirim"
    else
        bad "Header ${h} tidak ditemukan"
    fi
done
if grep -qi '^X-Powered-By:' <<<"${hdrs}"; then
    bad "EXP-8 header X-Powered-By terekspos"
else
    pass "EXP-8 X-Powered-By tidak terekspos"
fi
if grep -qiE '^Server:.*[0-9]+\.[0-9]+' <<<"${hdrs}"; then
    bad "EXP-8 header Server menampilkan versi"
else
    pass "EXP-8 header Server tidak menampilkan versi"
fi
# CORS ketat (docs/PO/1.1. Architecture.md, Application Tier): frontend dan API
# dilayani pada origin yang sama, sehingga CORS tidak diperlukan. Yang diperiksa
# adalah penegakan deny-by-default: tidak boleh ada wildcard origin.
if grep -qiE '^Access-Control-Allow-Origin:[[:space:]]*\*' <<<"${hdrs}"; then
    bad "CORS wildcard (Access-Control-Allow-Origin: *) terkirim; harus deny by default"
else
    pass "CORS ketat: tidak ada wildcard Access-Control-Allow-Origin"
fi

# --- Aplikasi & endpoint ----------------------------------------------------
echo "-- Frontend & API --"
rc="$(code "${HTTPS_BASE}/")"
if [[ "${rc}" == "200" ]]; then
    pass "Frontend tersedia (status 200)"
else
    bad "Frontend tidak mengembalikan 200 (status ${rc})"
fi

summary="$("${CURL[@]}" "${HTTPS_BASE}/api/dashboard/summary" 2>/dev/null)"
if python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("total_orders",0) > 0 else 1)' <<<"${summary}" 2>/dev/null; then
    pass "API mengembalikan data: ${summary}"
else
    bad "API belum mengembalikan data (respons: ${summary:-kosong})"
    info "Periksa: docker compose -f docker-compose.yml logs app db"
fi

# --- EXP-1 hanya GET/HEAD, EXP-3 path sensitif ------------------------------
echo "-- EXP-1 / EXP-3 (exposure control) --"
for m in POST PUT PATCH DELETE; do
    rc="$("${CURL[@]}" -X "${m}" -o /dev/null -w '%{http_code}' "${HTTPS_BASE}/" 2>/dev/null || echo 000)"
    if [[ "$rc" =~ ^2 ]]; then
        bad "EXP-1 metode ${m} diterima (status ${rc}); dashboard harus read-only"
    else
        pass "EXP-1 metode ${m} ditolak (status ${rc})"
    fi
done

for p in /.env /.git/config /storage/logs/laravel.log /vendor/composer/installed.json /composer.lock /artisan /phpinfo.php /telescope /horizon /_ignition/health-check /_debugbar/open; do
    rc="$(code "${HTTPS_BASE}${p}")"
    if [[ "${rc}" =~ ^(403|404|405|410)$ ]]; then
        pass "EXP-3 ${p} tidak dapat diakses (status ${rc})"
    else
        bad "EXP-3 ${p} dapat diakses (status ${rc})"
    fi
done

# --- Isolasi port (T-05) ----------------------------------------------------
echo "-- Isolasi jaringan (T-05, Tugas 3) --"
for pt in 3306 9000; do
    if timeout 3 bash -c "exec 3<>/dev/tcp/127.0.0.1/${pt}" 2>/dev/null; then
        bad "T-05 port ${pt} pada host TERBUKA (seharusnya hanya 80/443)"
    else
        pass "T-05 port ${pt} pada host tertutup"
    fi
done

# --- Least privilege (T-10) -------------------------------------------------
echo "-- Least privilege (T-10, Tugas 2) --"
app_uid="$(docker compose -f "${COMPOSE_FILE}" exec -T app id -u 2>/dev/null | tr -d '\r' || echo "")"
if [[ -n "${app_uid}" && "${app_uid}" != "0" ]]; then
    pass "T-10 container app berjalan sebagai non-root (uid ${app_uid})"
else
    bad "T-10 container app berjalan sebagai root atau tidak dapat diperiksa (uid '${app_uid}')"
fi

proxy_user="$(docker compose -f "${COMPOSE_FILE}" exec -T proxy id -un 2>/dev/null | tr -d '\r' || echo "")"
if [[ -n "${proxy_user}" && "${proxy_user}" != "root" ]]; then
    pass "T-10 container proxy berjalan sebagai non-root (${proxy_user})"
else
    bad "T-10 container proxy berjalan sebagai root atau tidak dapat diperiksa ('${proxy_user}')"
fi

# --- Least privilege database (arahan PO) ------------------------------------
# Kontrol ini menegakkan docs/PO/1.1. Architecture.md (Data Tier): user aplikasi
# hanya boleh punya SELECT. Diverifikasi dari SHOW GRANTS di dalam kontainer db,
# bukan dari asumsi konfigurasi.
echo "-- Least privilege database (PO: SELECT-only) --"
if [[ -f "${REPO_ROOT}/.env" ]]; then
    # shellcheck disable=SC1091
    set -a; . "${REPO_ROOT}/.env"; set +a
fi
db_user="${DB_USERNAME:-dss_user}"
# SQL dikirim sebagai argumen ($1) agar tidak perlu kutip bersarang; ekspansi
# $MYSQL_ROOT_PASSWORD terjadi di dalam shell kontainer, bukan di host.
grants="$(docker compose -f "${COMPOSE_FILE}" exec -T db \
    sh -c 'mysql --protocol=socket -uroot -p"$MYSQL_ROOT_PASSWORD" --silent --skip-column-names -e "$1"' \
    _ "SHOW GRANTS FOR '${db_user}'@'%';" 2>/dev/null | tr -d '\r' || true)"
if [[ -z "${grants}" ]]; then
    bad "Hak akses user '${db_user}' tidak dapat diperiksa (kontainer db belum siap?)"
elif grep -qiE '\b(ALL PRIVILEGES|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE)\b' <<<"${grants}"; then
    sed 's/^/      /' <<<"${grants}"
    bad "Least privilege: user '${db_user}' masih punya hak di luar SELECT"
elif grep -qi 'SELECT' <<<"${grants}"; then
    pass "Least privilege: user '${db_user}' hanya memiliki SELECT"
else
    bad "Least privilege: tidak menemukan SELECT pada hak akses '${db_user}'"
fi

# --- Security Gate milik Security Engineer ----------------------------------
if [[ "${GATE:-0}" == "1" ]]; then
    echo "-- Gate milik Security Engineer --"
    echo "  Gate 4: check-infra-policy.sh"
    ( cd "${REPO_ROOT}" && bash policy/scripts/check-infra-policy.sh docker-compose.yml )
    echo
    # verify-deployment.sh dihapus Security Engineer (commit 08d3996). Dijaga agar
    # skrip ini tetap berguna pada repositori yang belum/tidak memakainya.
    if [[ -f "${REPO_ROOT}/policy/scripts/verify-deployment.sh" ]]; then
        echo "  Verifikasi deployment (evidence disimpan di evidence/)"
        ( cd "${REPO_ROOT}" \
          && mkdir -p evidence \
          && DEV_INSECURE=1 EVIDENCE_DIR=evidence \
             bash policy/scripts/verify-deployment.sh "${HTTPS_BASE}" )
    else
        info "verify-deployment.sh tidak ada (milik Security Engineer) — dilewati."
    fi
else
    info "Jalankan ulang dengan GATE=1 untuk ikut menjalankan skrip Security Engineer."
fi

echo
echo "== Ringkasan: PASS=${PASS_N} FAIL=${FAIL_N} =="
[[ "${FAIL_N}" -eq 0 ]]
