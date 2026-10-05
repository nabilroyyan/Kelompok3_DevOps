#!/usr/bin/env bash
# =============================================================================
# Axon DSS — pembuat sertifikat TLS development (self-signed)
# Peran: Infrastructure/Platform Engineer
#
# MENGAPA SKRIP INI ADA
#   Nginx tidak dapat start tanpa `ssl_certificate`. Kebijakan TLS-5 pada
#   docs/SEC-ENG/policy/baseline/01-tls-baseline.md mengizinkan sertifikat
#   self-signed HANYA untuk development/pengujian Milestone ini, dan hasilnya
#   wajib dicatat sebagai "development" — bukan bukti kesiapan produksi.
#   Untuk produksi, gunakan CA tepercaya (mis. Let's Encrypt).
#
# KEAMANAN
#   Private key hanya dibuat di docs/INFRA/certs/, yang sudah masuk .gitignore.
#   JANGAN pernah meng-commit privkey.pem. Aturan repositori hanya mengizinkan
#   public key berada di folder `keys/` pada struktur standar.
#
# PEMAKAIAN
#   bash docs/INFRA/scripts/gen-certs.sh [hostname-atau-ip]
#   (tanpa argumen: nama host diambil dari APP_HOST pada docs/INFRA/.env)
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
CERT_DIR="${INFRA_DIR}/certs"

# Bila argumen tidak diberikan, ambil APP_HOST dari .env agar hanya ada satu
# sumber kebenaran untuk nama host.
if [[ -z "${1:-}" && -f "${INFRA_DIR}/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    . "${INFRA_DIR}/.env"
    set +a
fi

HOST="${1:-${APP_HOST:-localhost}}"

# SAN memuat localhost + loopback agar pengujian lokal
# (termasuk docs/SEC-ENG/policy/scripts/verify-deployment.sh) tetap dapat
# divalidasi, ditambah host/IP target deployment.
SAN="DNS:localhost,IP:127.0.0.1,IP:::1"
if [[ "${HOST}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    SAN="${SAN},IP:${HOST}"
elif [[ "${HOST}" != "localhost" ]]; then
    SAN="${SAN},DNS:${HOST}"
fi

mkdir -p "${CERT_DIR}"
umask 077   # private key tidak boleh terbaca pengguna lain sejak dibuat

openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -keyout "${CERT_DIR}/privkey.pem" \
    -out    "${CERT_DIR}/fullchain.pem" \
    -subj   "/CN=${HOST}/O=Kelompok 3 DevOps - Axon DSS (development)" \
    -addext "subjectAltName=${SAN}" \
    -addext "keyUsage=critical,digitalSignature,keyEncipherment" \
    -addext "extendedKeyUsage=serverAuth" \
    2>/dev/null

chmod 600 "${CERT_DIR}/privkey.pem"
chmod 644 "${CERT_DIR}/fullchain.pem"

echo "[certs] sertifikat development dibuat untuk host '${HOST}'"
echo "[certs]   certificate : ${CERT_DIR}/fullchain.pem"
echo "[certs]   private key : ${CERT_DIR}/privkey.pem  (JANGAN di-commit)"
echo "[certs]   status      : DEVELOPMENT (self-signed, bukan CA tepercaya)"
