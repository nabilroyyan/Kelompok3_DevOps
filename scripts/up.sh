#!/usr/bin/env bash
# =============================================================================
# Axon DSS — bootstrap + jalankan stack (peran Infra)
#
# Urutan yang dijalankan skrip ini:
#   1. Siapkan .env dari .env.example (bila belum ada).
#   2. Isi APP_KEY otomatis bila masih kosong.
#   3. Buat sertifikat TLS development (Nginx butuh sertifikat untuk start).
#   4. Validasi docker-compose.yml (docker compose config -q).
#   5. Build image lalu jalankan container.
#
# Pemakaian:
#   bash scripts/up.sh
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

COMPOSE=(docker compose -f docker-compose.yml)

echo "[up] direktori kerja: ${REPO_ROOT}"

# --- 1. Berkas .env ----------------------------------------------------------
if [[ ! -f .env ]]; then
    cp .env.example .env
    echo "[up] .env dibuat dari .env.example."
fi

# --- 2. APP_KEY -------------------------------------------------------------
if grep -qE '^APP_KEY=[[:space:]]*$' .env; then
    # 32 byte acak, base64 — format yang diharapkan Laravel untuk cipher default.
    # Delimiter `|` pada sed aman karena alfabet base64 tidak memuat karakter itu.
    key="base64:$(openssl rand -base64 32)"
    sed -i "s|^APP_KEY=.*|APP_KEY=${key}|" .env
    echo "[up] APP_KEY dibuat otomatis dan ditulis ke .env."
fi

# --- 3. Peringatan kredensial contoh ----------------------------------------
if grep -qE '^(MYSQL_ROOT_PASSWORD|DB_PASSWORD)=ubah-password-ini' .env; then
    echo "[up] PERINGATAN: password masih memakai nilai contoh dari .env.example." >&2
    echo "[up] Ganti MYSQL_ROOT_PASSWORD dan DB_PASSWORD di .env sebelum dipakai" >&2
    echo "[up] untuk deployment nyata (aturan Zero Tolerance Kredensial Bocor)." >&2
fi

# --- 4. Sertifikat TLS development ------------------------------------------
bash "${SCRIPT_DIR}/gen-certs.sh"

# --- 5. Validasi lalu build & jalankan --------------------------------------
echo "[up] memvalidasi docker-compose.yml"
"${COMPOSE[@]}" config -q

echo "[up] membangun image"
"${COMPOSE[@]}" build

echo "[up] menjalankan container"
"${COMPOSE[@]}" up -d

echo "[up] selesai. Langkah berikutnya:"
echo "     docker compose -f docker-compose.yml ps"
echo "     bash scripts/smoke-test.sh"
