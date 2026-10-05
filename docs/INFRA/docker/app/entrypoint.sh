#!/bin/sh
# =============================================================================
# Axon DSS — entrypoint service `app` (php-fpm)   [peran Infra]
#
# Tujuan:
#   1. Tidak menggantungkan keberhasilan start pada urutan initdb MySQL.
#      `depends_on: service_healthy` menjamin mysqld menjawab ping, tetapi
#      skrip inisialisasi /docker-entrypoint-initdb.d masih bisa berjalan.
#   2. Memberi peringatan awal bila konfigurasi kritis (APP_KEY) belum diisi,
#      sehingga kesalahan konfigurasi cepat terlihat di `docker compose logs`.
#
# Setelah itu seluruh argumen diteruskan ke proses utama dengan `exec`, agar
# php-fpm menjadi PID 1 dan menerima sinyal stop dari Docker dengan benar.
# =============================================================================
set -eu

DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-3306}"
DB_DATABASE="${DB_DATABASE:-classicmodels}"
DB_USERNAME="${DB_USERNAME:-axon}"

MAX_ATTEMPTS=60
attempt=1

echo "[entrypoint] menunggu database ${DB_HOST}:${DB_PORT} (dbname=${DB_DATABASE})"

while :; do
    if php -r '
        $dsn = sprintf(
            "mysql:host=%s;port=%s;dbname=%s",
            getenv("DB_HOST") ?: "db",
            getenv("DB_PORT") ?: "3306",
            getenv("DB_DATABASE") ?: "classicmodels"
        );
        try {
            new PDO($dsn, getenv("DB_USERNAME") ?: "axon", getenv("DB_PASSWORD") ?: "");
            exit(0);
        } catch (Throwable $e) {
            exit(1);
        }
    ' 2>/dev/null; then
        echo "[entrypoint] database siap"
        break
    fi

    if [ "$attempt" -ge "$MAX_ATTEMPTS" ]; then
        echo "[entrypoint] PERINGATAN: database belum siap setelah ${MAX_ATTEMPTS} percobaan." >&2
        echo "[entrypoint] php-fpm tetap dijalankan; endpoint /api akan error sampai database siap." >&2
        break
    fi

    attempt=$((attempt + 1))
    sleep 2
done

if [ -z "${APP_KEY:-}" ]; then
    echo "[entrypoint] PERINGATAN: APP_KEY kosong. Isi APP_KEY di docs/INFRA/.env." >&2
fi

exec "$@"
