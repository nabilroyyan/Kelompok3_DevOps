#!/bin/sh
# =============================================================================
# Axon DSS — menegakkan least privilege pada user database aplikasi
# Peran: Infrastructure/Platform Engineer
#
# DASAR KEBIJAKAN
#   docs/PO/1.1. Architecture.md (Data Tier, Prinsip Keamanan Basis Data):
#     "Pengguna database aplikasi DSS di lingkungan produksi wajib dibatasi
#      hanya memiliki hak akses SELECT
#      (GRANT SELECT ON classicmodels.* TO 'dss_user'@'%';)"
#   docs/PO/1.2 Risk.md: Zero Tolerance untuk SQLi — hak tulis tidak diperlukan
#   oleh dashboard yang murni read-only.
#
# KAPAN DIJALANKAN
#   Berkas ini di-mount ke /docker-entrypoint-initdb.d/ pada image resmi MySQL.
#   Entrypoint resmi menjalankan docker_setup_db (membuat database + user +
#   GRANT ALL) SEBELUM memproses berkas initdb, sehingga di sini kita bisa
#   mencabut hak berlebih yang baru saja diberikan itu.
#   Nomor berkas 20- memastikan ia berjalan SETELAH impor skema 10-.
#   Berjalan hanya sekali, yaitu saat volume data masih kosong.
#
# CARA KERJA
#   1. Cabut seluruh hak pada database aplikasi, termasuk GRANT OPTION.
#   2. Berikan ulang hanya SELECT.
#   3. Verifikasi hasilnya dengan SHOW GRANTS. Bila masih ada hak tulis, skrip
#      keluar dengan status bukan-nol sehingga inisialisasi database GAGAL dan
#      container berhenti. Prinsipnya fail-closed: lebih baik tidak jalan
#      daripada jalan dengan hak berlebih.
#
# CATATAN DAMPAK (disengaja)
#   User ini TIDAK dapat menjalankan `php artisan migrate` karena butuh DDL.
#   Dashboard bersifat read-only dan skema + data sudah utuh di dalam dump,
#   jadi migrasi tidak diperlukan di kontainer. Prosedur bila suatu saat butuh
#   DDL ada di docs/panduan-build-run.md (memakai kredensial root, sekali jalan).
#
# CATATAN KEAMANAN
#   Tidak ada password yang ditulis literal di sini; seluruhnya dari variabel
#   environment container (memenuhi T-06 dan pemeriksaan otomatis Gate 4).
# =============================================================================
set -u

: "${MYSQL_DATABASE:?MYSQL_DATABASE belum diset}"
: "${MYSQL_USER:?MYSQL_USER belum diset}"
: "${MYSQL_ROOT_PASSWORD:?MYSQL_ROOT_PASSWORD belum diset}"

DB_NAME="${MYSQL_DATABASE}"
APP_USER="${MYSQL_USER}"

# Validasi bentuk nama agar tidak bisa dipakai menyuntik SQL lewat environment.
for value in "${DB_NAME}" "${APP_USER}"; do
    case "${value}" in
        *[!A-Za-z0-9_]*|'')
            echo "[initdb] GAGAL: nama '${value}' hanya boleh huruf, angka, dan underscore." >&2
            exit 1
            ;;
    esac
done

mysql_exec() {
    mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" --force --silent -e "$1"
}

mysql_query() {
    mysql --protocol=socket -uroot -p"${MYSQL_ROOT_PASSWORD}" --silent --skip-column-names -e "$1"
}

echo "[initdb] Menegakkan least privilege SELECT-only untuk '${APP_USER}' pada '${DB_NAME}'"

# --force dipakai karena REVOKE bisa gagal bila haknya memang belum ada
# (misalnya saat skrip ini dijalankan ulang secara manual). Kegagalan di sini
# bukan masalah; verifikasi di bawah yang menentukan.
mysql_exec "REVOKE ALL PRIVILEGES ON \`${DB_NAME}\`.* FROM '${APP_USER}'@'%';"
mysql_exec "REVOKE GRANT OPTION ON \`${DB_NAME}\`.* FROM '${APP_USER}'@'%';"
mysql_exec "GRANT SELECT ON \`${DB_NAME}\`.* TO '${APP_USER}'@'%';"
mysql_exec "FLUSH PRIVILEGES;"

GRANTS="$(mysql_query "SHOW GRANTS FOR '${APP_USER}'@'%';")"
printf '%s\n' "${GRANTS}"

if printf '%s\n' "${GRANTS}" \
    | grep -qiE '\b(ALL PRIVILEGES|INSERT|UPDATE|DELETE|DROP|ALTER|CREATE|REFERENCES|INDEX|GRANT OPTION)\b'; then
    echo "[initdb] GAGAL: '${APP_USER}' masih memiliki hak di luar SELECT." >&2
    echo "[initdb] Inisialisasi dihentikan agar kontainer tidak berjalan dengan hak berlebih." >&2
    exit 1
fi

echo "[initdb] OK: '${APP_USER}' hanya memiliki SELECT pada ${DB_NAME}"
