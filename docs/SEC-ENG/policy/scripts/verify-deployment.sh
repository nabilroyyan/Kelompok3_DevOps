#!/usr/bin/env bash
# Verifikasi deployment terhadap baseline Security (TLS, Exposure Control) dan hasilkan EVIDENCE.
# Dijalankan oleh Security setelah Platform men-deploy stack.
#
# Pemakaian:
#   bash policy/scripts/verify-deployment.sh https://dashboard.example.local [DB_HOST]
#   DEV_INSECURE=1 bash policy/scripts/verify-deployment.sh https://localhost   # sertifikat self-signed (development)
#   SKIP_TLS=1     bash policy/scripts/verify-deployment.sh http://localhost:8080 # uji lokal tanpa TLS
#
# Output: evidence/verify-<waktu>.txt  (lampirkan di risk-register sebagai Evidence)
set -uo pipefail

BASE="${1:?Pemakaian: $0 <base-url> [db-host]}"
DB_HOST="${2:-}"
HOST="$(echo "$BASE" | sed -E 's#^[a-z]+://##; s#[:/].*$##')"
PORT_HTTPS="${HTTPS_PORT:-443}"
CURL=(curl -sS -o /dev/null --max-time 10)
[[ "${DEV_INSECURE:-0}" == "1" ]] && CURL+=(-k)

OUT_DIR="${EVIDENCE_DIR:-evidence}"; mkdir -p "$OUT_DIR"
OUT="$OUT_DIR/verify-$(date -u +%Y%m%dT%H%M%SZ).txt"
FAIL=0; PASS_N=0; FAIL_N=0; SKIP_N=0

log()  { echo "$*" | tee -a "$OUT"; }
pass() { PASS_N=$((PASS_N+1)); log "[PASS] $1"; }
bad()  { FAIL=1; FAIL_N=$((FAIL_N+1)); log "[FAIL] $1"; }
skip() { SKIP_N=$((SKIP_N+1)); log "[SKIP] $1"; }
code() { "${CURL[@]}" -w '%{http_code}' "$@" 2>/dev/null || echo 000; }

log "== Verifikasi Deployment Axon DSS =="
log "Target   : $BASE"
log "Waktu    : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
[[ "${DEV_INSECURE:-0}" == "1" ]] && log "Mode     : DEVELOPMENT (sertifikat tidak divalidasi), hasil bukan untuk produksi"
log ""

# ---------------- TLS ----------------
log "-- TLS Baseline (01-tls-baseline.md) --"
if [[ "${SKIP_TLS:-0}" == "1" ]]; then
  skip "TLS-1..TLS-3 dilewati (SKIP_TLS=1)"
else
  # TLS-2: redirect HTTP -> HTTPS
  http_url="http://${HOST}${HTTP_PORT:+:$HTTP_PORT}/"
  rc=$(code -w '%{http_code}' "$http_url"); loc=$("${CURL[@]}" -I "$http_url" -w '%{redirect_url}' 2>/dev/null)
  if [[ "$rc" =~ ^30[18]$ && "$loc" == https://* ]]; then pass "TLS-2 HTTP dialihkan permanen ke HTTPS ($rc -> $loc)"
  else bad "TLS-2 HTTP tidak dialihkan permanen ke HTTPS (status=$rc)"; fi

  if command -v openssl >/dev/null; then
    for v in tls1_2 tls1_3; do
      if echo | openssl s_client -connect "${HOST}:${PORT_HTTPS}" -servername "$HOST" -$v >/dev/null 2>&1; then pass "TLS-1 ${v} diterima"
      else bad "TLS-1 ${v} ditolak (seharusnya didukung)"; fi
    done
    for v in tls1 tls1_1; do
      out=$(echo | openssl s_client -connect "${HOST}:${PORT_HTTPS}" -servername "$HOST" -$v 2>&1)
      if echo "$out" | grep -qiE "unknown option|unsupported|no protocols available"; then skip "TLS-1 ${v}: openssl lokal tidak mendukung uji protokol ini (gunakan testssl.sh)"
      elif echo "$out" | grep -q "BEGIN CERTIFICATE\|Cipher is [A-Z0-9]"; then bad "TLS-1 ${v} masih DITERIMA (harus dimatikan)"
      else pass "TLS-1 ${v} ditolak"; fi
    done
  else skip "openssl tidak tersedia, uji versi TLS dilewati"; fi
fi
log ""

# ---------------- Header ----------------
log "-- Security Header (02-exposure-control.md, 2.3) --"
HDRS=$(curl -sS -I --max-time 10 $([[ "${DEV_INSECURE:-0}" == "1" ]] && echo -k) "$BASE/" 2>/dev/null | tr -d '\r')
check_hdr() { # nama, pola-nilai-opsional
  if echo "$HDRS" | grep -iq "^$1:.*${2:-}"; then pass "Header $1 ada"; else bad "Header $1 tidak ada${2:+ / nilai tidak sesuai ($2)}"; fi
}
check_hdr "Strict-Transport-Security" "max-age=[0-9]\{8,\}"
check_hdr "X-Content-Type-Options" "nosniff"
check_hdr "X-Frame-Options" "DENY\|SAMEORIGIN"
check_hdr "Referrer-Policy"
check_hdr "Content-Security-Policy"
check_hdr "Permissions-Policy"
if echo "$HDRS" | grep -iq '^X-Powered-By:'; then bad "EXP-8 header X-Powered-By terekspos"; else pass "EXP-8 tidak ada X-Powered-By"; fi
if echo "$HDRS" | grep -iE '^Server:.*[0-9]+\.[0-9]+' >/dev/null; then bad "EXP-8 header Server menampilkan versi"; else pass "EXP-8 header Server tidak menampilkan versi"; fi
log ""

# ---------------- Endpoint ----------------
log "-- Exposure Control: endpoint (EXP-1, EXP-3) --"
for m in POST PUT PATCH DELETE; do
  rc=$(code -X "$m" "$BASE/")
  if [[ "$rc" =~ ^2 ]]; then bad "EXP-1 metode $m diterima ($rc), dashboard harus read-only"; else pass "EXP-1 metode $m ditolak ($rc)"; fi
done
for p in /.env /.env.backup /.git/config /storage/logs/laravel.log /vendor/composer/installed.json /composer.lock /artisan /phpinfo.php /telescope /horizon /_ignition/health-check /_debugbar/open; do
  rc=$(code "$BASE$p")
  if [[ "$rc" =~ ^(403|404|405|410)$ ]]; then pass "EXP-3 $p tidak dapat diakses ($rc)"; else bad "EXP-3 $p dapat diakses (status $rc)"; fi
done
log ""

# ---------------- Port ----------------
log "-- Exposure Control: port (02-exposure-control.md, 2.1) --"
if [[ -n "$DB_HOST" ]]; then
  for pt in 5432 9000; do
    if (exec 3<>"/dev/tcp/$DB_HOST/$pt") 2>/dev/null; then exec 3>&- 3<&-; bad "Port $pt pada $DB_HOST TERBUKA dari titik uji (harus tertutup)"
    else pass "Port $pt pada $DB_HOST tertutup dari titik uji"; fi
  done
else
  skip "Uji port DB/php-fpm dilewati (argumen kedua DB_HOST tidak diberikan; jalankan dari luar jaringan Docker)"
fi
log ""

log "== Ringkasan: PASS=$PASS_N FAIL=$FAIL_N SKIP=$SKIP_N =="
log "Laporan   : $OUT"
exit $FAIL
