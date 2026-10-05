# Panduan Build, Run, Verifikasi, dan Deploy

Dokumen ini adalah langkah operasional untuk artefak di `docs/INFRA/`.
Semua perintah di bawah **belum dijalankan** pada sesi penyusunan artefak ini —
urutan dan hasil yang diharapkan ditulis eksplisit supaya mudah dibuktikan
sekaligus mudah dilaporkan sebagai bukti praktikum.

---

## 0. Prasyarat

| Kebutuhan | Cara memeriksa | Catatan |
| :--- | :--- | :--- |
| Docker Engine | `docker version` | Client & Server harus tampil |
| Docker Compose v2 | `docker compose version` | Perintah memakai sintaks `docker compose` (bukan `docker-compose`) |
| Port 80 & 443 host bebas | `ss -ltnp \| grep -E ':(80\|443)'` | Bila terpakai, ubah `HTTP_PORT`/`HTTPS_PORT` pada `.env` |
| `openssl` | `openssl version` | Dipakai `scripts/gen-certs.sh` |
| Ruang disk | `docker system df` | Image Nginx + PHP + Node build ± 1 GB |
| Akses internet | — | Diperlukan saat build (pull base image, `composer install`, `npm ci`) |
| PHP 8.4 **>= 8.4.1** | `docker run --rm php:8.4-cli php -v` (opsional) | Bukan untuk host, tetapi jadi acuan: `composer.lock` mensyaratkan >= 8.4.1, dan image backend memakai `ARG PHP_VERSION=8.4`. Host tidak perlu memasang PHP. |

> Build pertama adalah yang paling lama karena harus menarik base image dan
> memasang dependensi PHP serta Node. Build berikutnya jauh lebih cepat karena
> cache layer.

---

## 1. Konfigurasi

```bash
cd docs/INFRA
cp .env.example .env
```

Isi nilai berikut pada `.env`:

| Variabel | Wajib | Nilai contoh | Keterangan |
| :--- | :---: | :--- | :--- |
| `MYSQL_ROOT_PASSWORD` | ✅ | string acak kuat | Hanya untuk administrasi di dalam container |
| `DB_PASSWORD` | ✅ | string acak kuat | Dipakai aplikasi (`DB_USERNAME`, default `dss_user`). User ini **hanya punya hak `SELECT`** — lihat §5.5 |
| `APP_KEY` | ✅ | `base64:...` | Boleh dikosongkan — `scripts/up.sh` akan mengisinya otomatis |
| `APP_HOST` | ✅ | `localhost` | Menentukan CN/SAN sertifikat development |
| `PUBLISH_ADDR` | — | `0.0.0.0` | `127.0.0.1` bila Nginx host yang menjadi pintu masuk publik |
| `HTTP_PORT` / `HTTPS_PORT` | — | `80` / `443` | Ubah bila port host terpakai |

Membuat `APP_KEY` secara manual (opsional, sama dengan yang dilakukan `up.sh`):

```bash
printf 'base64:%s\n' "$(openssl rand -base64 32)"
```

> Mengapa `APP_KEY` tidak ditulis langsung ke `.env.example`? Karena nilai itu
> adalah rahasia: `Laravel` memakainya untuk enkripsi dan penandatanganan.
> Aturan PO menetapkan Zero Tolerance untuk kredensial yang masuk repositori.

---

## 2. Sertifikat TLS development

```bash
bash scripts/gen-certs.sh
```

Hasil yang diharapkan:

```text
[certs] sertifikat development dibuat untuk host 'localhost'
[certs]   certificate : .../docs/INFRA/certs/fullchain.pem
[certs]   private key : .../docs/INFRA/certs/privkey.pem  (JANGAN di-commit)
[certs]   status      : DEVELOPMENT (self-signed, bukan CA tepercaya)
```

Periksa isinya bila perlu:

```bash
openssl x509 -in certs/fullchain.pem -noout -subject -ext subjectAltName -dates
```

> **Mengapa langkah ini terpisah dan wajib?** Nginx menolak start bila
> `ssl_certificate` tidak ada. Sertifikat self-signed hanya sah untuk
> pengujian (TLS-5). Untuk produksi, ganti dengan sertifikat CA tepercaya
> — lihat bagian 8.

---

## 3. Validasi, lalu build

```bash
# Validasi berkas Compose tanpa menjalankan apa pun.
docker compose config -q

# Membangun image `app` dan `proxy`.
docker compose build
```

`docker compose config -q` tidak menghasilkan keluaran bila berkas valid.
Bila ada variabel `.env` yang belum diisi, perintah ini akan berhenti dengan
pesan seperti `required variable APP_KEY is missing`.

Periksa hasil build:

```bash
docker images | grep axon
```

---

## 4. Menjalankan stack

```bash
docker compose up -d
docker compose ps
```

Hasil yang diharapkan pada `docker compose ps`: tiga service berjalan dengan
status **healthy** pada `app`, `db`, dan `proxy`.

```text
NAME             IMAGE              STATUS
axon-dss-app-1   axon-dss-app       Up (healthy)
axon-dss-db-1    mysql:8.0          Up (healthy)
axon-dss-proxy-1 axon-dss-proxy     Up (healthy)
```

Ikuti proses inisialisasi database (impor `classicmodels`) sampai selesai:

```bash
docker compose logs -f db
```

> Berhenti mengikuti log dengan `Ctrl+C` — container tetap berjalan.

Bila ingin semuanya sekaligus (konfigurasi → sertifikat → build → up), gunakan:

```bash
bash scripts/up.sh
```

---

## 5. Verifikasi

Jalankan uji asap (semua pemeriksaan mencantumkan kode kontrol yang diuji):

```bash
bash scripts/smoke-test.sh
```

Perintah manual beserta **hasil yang diharapkan**:

| # | Perintah | Hasil yang diharapkan | Kontrol |
| :-: | :--- | :--- | :--- |
| 1 | `curl -I http://localhost/` | `301` dengan `Location: https://localhost/` | TLS-2 |
| 2 | `curl -kI https://localhost/` | `200` + `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Permissions-Policy`, `Content-Security-Policy` | TLS-3, EXP 2.3 |
| 3 | `curl -k https://localhost/api/dashboard/summary` | JSON `{"total_customers":…,"total_products":…,"total_orders":…}` dengan nilai **> 0** | Bukti DB terisi + jalur proxy→fpm→db hidup |
| 4 | `curl -k -o /dev/null -w '%{http_code}\n' -X POST https://localhost/` | `405` | EXP-1 |
| 5 | `curl -k -o /dev/null -w '%{http_code}\n' https://localhost/.env` | `404` | EXP-3 |
| 6 | `curl -k -o /dev/null -w '%{http_code}\n' https://localhost/phpinfo.php` | `404` | EXP-3 |
| 7 | `docker compose port db 3306` | pesan "tidak ada published port" (bukan `0.0.0.0:3306`) | T-05 |
| 8 | `nc -z 127.0.0.1 3306` (atau `timeout 3 bash -c 'exec 3<>/dev/tcp/127.0.0.1/3306'`) | gagal / timeout | T-05 |
| 9 | `docker compose port app 9000` | pesan "tidak ada published port" (bukan `0.0.0.0:9000`) | TLS-6 |
| 10 | `docker compose exec app id` | `uid=82(www-data)` — bukan `uid=0` | T-10 |
| 11 | `docker compose exec proxy id` | `uid=101(nginx)` — bukan `uid=0` | T-10 |
| 12 | `echo \| openssl s_client -connect localhost:443 -tls1_2 2>&1 \| grep -i protocol` | handshake berhasil | TLS-1 |
| 13 | `echo \| openssl s_client -connect localhost:443 -tls1_1 2>&1 \| grep -iE 'alert\|error'` | gagal (protokol ditolak) | TLS-1 |
| 14 | `docker compose exec db sh -c 'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SHOW TABLES;"'` | 8 tabel `classicmodels` | Bukti Tugas 1 |
| 15 | `docker compose exec db sh -c 'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE" -e "SELECT COUNT(*) FROM orders;"'` | jumlah baris > 0 (dataset `classicmodels` standar: 326) | Bukti DB terisi |
| 16 | `docker compose logs --tail 5 proxy` | baris JSON dengan `ts`, `ip`, `req_id`, `method`, `path`, `status`, `rt`, `bytes`, `ua` | LOG-1..LOG-3 |
| 17 | `docker compose exec db sh -c 'mysql --protocol=socket -uroot -p"$MYSQL_ROOT_PASSWORD" -e "SHOW GRANTS FOR '\''dss_user'\''@'\''%'\'';"'` | hanya `GRANT USAGE` dan **`GRANT SELECT`**; tidak ada INSERT/UPDATE/DELETE/DROP/ALTER | Least privilege (arahan PO) |
| 18 | `curl -kI https://localhost/ \| grep -i access-control-allow-origin` | tidak ada keluaran (deny by default) | CORS ketat (architecture §2) |
| 19 | `docker compose exec app php -v` | PHP **8.4.x** (bukan 8.3) | PHP 8.4 (syarat `composer.lock`) |

### 5.5 Konsekuensi user database `SELECT`-only

`docker/db/20-app-user-privileges.sh` mencabut hak berlebih user aplikasi dan menyisakan
`SELECT` saja, sesuai `docs/PO/1.1. Architecture.md` (Data Tier). Skrip itu **memverifikasi**
hasilnya lewat `SHOW GRANTS`; bila masih ada hak tulis, inisialisasi database digagalkan
sehingga container tidak pernah berjalan dengan hak berlebih.

Dampak yang perlu kamu tahu:

| Operasi | Bisa dilakukan `dss_user`? | Catatan |
| :--- | :---: | :--- |
| Query analitik dashboard (SELECT) | ✅ | Seluruh 12 endpoint read-only tetap berfungsi |
| `php artisan migrate` | ❌ | Butuh DDL — memang disengaja |
| Perbaikan data manual | ❌ | Pakai kredensial root (di bawah) |

Dashboard tidak memerlukan migrasi: skema beserta data sudah utuh di dalam dump yang
diimpor saat inisialisasi. Laravel tetap dapat memakai query Builder pada tabel yang ada.

**Bila suatu saat benar-benar butuh DDL** (misalnya menambah indeks untuk performa),
lakukan sekali jalan dengan kredensial root, jangan dengan membuka hak `dss_user`:

```bash
docker compose -f docs/INFRA/docker-compose.yml exec db \
  sh -c 'mysql --protocol=socket -uroot -p"$MYSQL_ROOT_PASSWORD" classicmodels -e "ALTER TABLE orders ADD INDEX idx_orderdate (orderDate);"'
```

Hak `dss_user` tetap `SELECT`; perubahan skema tidak mengubah batas keamanan aplikasi.

> **Catatan TLS-1 langkah 13.** Bila `openssl` versi lokal sudah tidak
> mendukung `-tls1_1`, uji ini akan gagal karena alasan teknis, bukan karena
> konfigurasi. Pakai `testssl.sh` atau `nmap --script ssl-enum-ciphers`
> sebagai pembanding.

---

## 6. Bukti & Gate Security

```bash
GATE=1 bash scripts/smoke-test.sh
```

Perintah tersebut menjalankan dua artefak milik Security Engineer:

```bash
# Gate 4 — kebijakan infra (dijalankan dari root repositori)
bash docs/SEC-ENG/policy/scripts/check-infra-policy.sh docs/INFRA/docker-compose.yml

# Verifikasi deployment TLS/Exposure — bukti tersimpan di docs/INFRA/evidence/
DEV_INSECURE=1 EVIDENCE_DIR=docs/INFRA/evidence \
  bash docs/SEC-ENG/policy/scripts/verify-deployment.sh https://localhost
```

Keluaran `check-infra-policy.sh` yang diharapkan:

```text
[OK] T-05: service database tidak mem-publish port ke host
[OK] T-06: tidak ada password/APP_KEY literal di docs/INFRA/docker-compose.yml
[OK] T-07: APP_DEBUG tidak aktif di docs/INFRA/docker-compose.yml
[OK] T-10: ./docs/INFRA/docker/app/Dockerfile memakai USER www-data
[OK] T-10: ./docs/INFRA/docker/proxy/Dockerfile memakai USER nginx
[OK] T-06: .env tidak ter-track di Git
[OK] T-11: semua aset CDN memakai SRI (atau tidak ada aset CDN)
```

Bukti yang layak dikumpulkan untuk laporan UTS:

- tangkapan layar `docker compose ps` (semua `healthy`);
- tangkapan layar dashboard di `https://localhost/` (grafik terisi data);
- keluaran `curl -k .../api/dashboard/summary`;
- keluaran `check-infra-policy.sh` dan `verify-deployment.sh` (folder `evidence/`);
- sampel baris access log JSON dari `docker compose logs proxy`.

> `docs/INFRA/evidence/` sudah masuk `.gitignore`. Simpan hasil verifikasi di
> sana agar tidak ikut ter-commit, lalu lampirkan pada laporan.

---

### 6.1 Menjalankan gate yang sama secara lokal

Pipeline GitHub Actions ada di [`.github/workflows/ci.yml`](../../../.github/workflows/ci.yml).
Agar tidak perlu menunggu pipeline untuk hal yang bisa diketahui lebih cepat:

```bash
# Gate 1 (secret scan), Gate 3 (SCA + SBOM), Gate 4 (infra policy + Hadolint)
bash docs/INFRA/scripts/run-gates-local.sh

# Menambahkan Gate 5 (build image lalu scan container)
WITH_IMAGE=1 bash docs/INFRA/scripts/run-gates-local.sh
```

Skrip memakai tool dan versi yang sama dengan pipeline (Trivy 0.58.0,
Gitleaks v8.28.0, Hadolint 2.12.0) supaya hasil lokal dan hasil pipeline tidak
berbeda. Laporan ditulis ke `docs/INFRA/evidence/gates-local-<waktu>.log`.

Untuk mengisi folder laporan milik Security Engineer (butir 3 backlog PO pada
`README.md`), arahkan `REPORTS_DIR` ke sana. Skrip juga menghasilkan laporan
mesin-terbaca, bukan hanya log teks:

```bash
REPORTS_DIR=docs/SEC-ENG/reports bash docs/INFRA/scripts/run-gates-local.sh
```

| Berkas yang dihasilkan | Isi |
| :--- | :--- |
| `gitleaks.sarif` | Temuan secret (dapat diunggah ke tab Security GitHub) |
| `trivy-fs.sarif` | Temuan CVE/misconfig dependensi |
| `trivy-fs.json` | Arsip bukti terstruktur |
| `gates-local-<waktu>.log` | Log lengkap seluruh gate |

### 6.2 Menghasilkan SBOM

```bash
bash docs/INFRA/scripts/generate-sbom.sh                  # tulis ke <app>/sbom/
OUT_DIR=/tmp/sbom bash docs/INFRA/scripts/generate-sbom.sh  # tulis ke folder lain
bash docs/INFRA/scripts/generate-sbom.sh --stdout backend   # cetak ke layar
```

Menghasilkan CycloneDX untuk backend (`composer.lock`) dan frontend
(`package-lock.json`). Ini menutup Prioritas P1 pada `docs/PO/2.1 Developer Analysis
Result.md`. Kepemilikan isi SBOM tetap milik Developer (Tugas 3 mereka); skrip ini
hanya menyediakan otomatisasinya dan **tidak** mengubah `composer.json` Developer.

Berkas keluaran berada di `docs/Dev/axon-devsecops-dss/sbom/` sesuai struktur pada
`README.md` repositori.

### 6.3 Mengaktifkan Gate 2 (SonarCloud)

1. Masuk ke SonarCloud, buat organisasi, lalu buat project dengan key `axon-dss-dashboard`
   (sama dengan `sonar.projectKey` pada berkas milik Security Engineer).
2. Buat token analisis, lalu di GitHub buka
   *Settings → Secrets and variables → Actions*:
   - **Secret** `SONAR_TOKEN` = token tadi.
   - **Variable** `SONAR_ORGANIZATION` = slug organisasi SonarCloud kamu.
   - **Variable** `SONAR_HOST_URL` = `https://sonarcloud.io` (boleh dikosongkan; default kode sudah ini).
3. Tambahkan **branch protection** untuk `dev` dan `main` dengan required status check
   **`Security Gate - PASSED`** supaya gate menjadi wajib.
4. Jalankan sekali `docs/SEC-ENG/policy/sonarqube/setup-quality-gate.sh` (milik Security
   Engineer) bila ingin memakai Quality Gate `Axon-DSS-Baseline`.

Tanpa langkah 1–2, job Sonar dilewati dengan peringatan dan pipeline **tetap hijau** —
dirancang begitu agar CI berguna sejak hari pertama.

> **Yang perlu diketahui:** Gate 2 saat ini **non-blocking**, karena Quality Gate
> mensyaratkan `new_coverage >= 70%` sedangkan tes yang ada baru dua berkas skeleton
> Laravel. Setelah Developer menambah tes, hapus `continue-on-error` pada job
> `sast-sonar` untuk menjadikannya gate yang memblokir.

---

## 7. Operasional harian

```bash
cd docs/INFRA

# Status & kesehatan
docker compose ps

# Log (access log JSON ada di sini)
docker compose logs -f proxy
docker compose logs -f app
docker compose logs -f db

# Menghentikan tanpa menghapus data
docker compose stop
docker compose start

# Memuat ulang setelah mengubah nginx.conf (butuh rebuild image proxy)
docker compose build proxy && docker compose up -d proxy

# Memuat ulang setelah mengubah .env
docker compose up -d --force-recreate app

# Reset total (MENGHAPUS data MySQL dan cache Laravel)
docker compose down -v
```

Urutan diagnosa saat ada masalah: **status → log → network → volume → konfigurasi**.
Lihat tabel troubleshooting pada [README.md](../README.md#6-troubleshooting).

---

## 8. Deploy di VPS

Ada dua pilihan. Pilih salah satu, jangan keduanya pada port yang sama.

### Skenario A — container sebagai pintu masuk (paling sederhana)

`.env`:

```env
PUBLISH_ADDR=0.0.0.0
HTTP_PORT=80
HTTPS_PORT=443
APP_HOST=dashboard.example.com   # atau IP publik VPS
```

```bash
bash scripts/gen-certs.sh dashboard.example.com   # atau IP publik VPS
docker compose up -d
```

Sertifikat masih self-signed. Untuk produksi:

1. Terbitkan sertifikat dari CA tepercaya (mis. Let's Encrypt) untuk
   `APP_HOST`, lalu salin ke `certs/fullchain.pem` dan `certs/privkey.pem`
   (`privkey.pem` tetap permission `600`).
2. Muat ulang: `docker compose restart proxy`.
3. Pastikan port 80 tetap terbuka — hanya untuk redirect ke HTTPS dan
   verifikasi domain saat penerbitan sertifikat.

### Skenario B — Nginx host terpisah (sesuai pola Bab 4: terminasi TLS di host)

Container hanya boleh dijangkau dari loopback:

```env
PUBLISH_ADDR=127.0.0.1
HTTP_PORT=8080
HTTPS_PORT=8443
```

Konfigurasi pada Nginx host:

```nginx
server {
    listen 80;
    server_name dashboard.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    http2 on;
    server_name dashboard.example.com;

    ssl_certificate     /etc/letsencrypt/live/dashboard.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/dashboard.example.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    location / {
        proxy_pass https://127.0.0.1:8443;
        proxy_ssl_verify off;          # upstream memakai sertifikat self-signed
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_read_timeout 60s;
    }
}
```

> Pada skenario ini, header keamanan dan pembatasan metode **tetap** diterapkan
> dua kali (di Nginx host dan di container), sehingga tidak ada kontrol yang
> hilang. Header yang dikirim ulang tidak menimbulkan masalah; yang perlu
> dipastikan hanya tidak ada `add_header` di Nginx host yang menimpa header
> container dengan nilai lebih lemah.

Yang perlu dipastikan setelah deploy:

- `docker compose port db 3306` tetap kosong — isolasi tidak berubah meski di VPS.
- Port host yang tersisa hanya 80/443 (atau 8080/8443 pada skenario B).
- Sertifikat produksi tidak memakai file dari `certs/` development.

---

## 9. Reset total (mulai dari nol)

```bash
cd docs/INFRA
docker compose down -v --remove-orphans
rm -rf certs/fullchain.pem certs/privkey.pem
bash scripts/up.sh
```

`docker compose down -v` menghapus volume `db-data` dan `app-storage`, sehingga
database akan diimpor ulang dari dump saat container `db` dibuat kembali.

---

## 10. Lampiran: berkas yang dihasilkan saat menjalankan

| Path | Isi | Masuk Git? |
| :--- | :--- | :---: |
| `.env` | Kredensial runtime | ❌ (gitignored) |
| `certs/fullchain.pem`, `certs/privkey.pem` | Sertifikat development | ❌ (gitignored) |
| `evidence/verify-*.txt` | Bukti hasil `verify-deployment.sh` | ❌ (gitignored) |
| `evidence/gates-local-*.log` | Bukti hasil `run-gates-local.sh` | ❌ (gitignored) |
| `docs/SEC-ENG/reports/*.sarif`, `*.json` | Laporan audit mesin-terbaca (butir 3 backlog PO) | ✅ dimaksudkan sebagai bukti yang di-commit |
| `docs/Dev/axon-devsecops-dss/sbom/*.cdx.json` | SBOM CycloneDX hasil `generate-sbom.sh` | boleh di-commit sebagai bukti (milik Developer) |
| Volume `axon-dss_db-data` | Data MySQL | — (Docker) |
| Volume `axon-dss_app-storage` | Cache/log/sesi Laravel | — (Docker) |
