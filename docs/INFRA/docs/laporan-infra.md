# Laporan Infra — Milestone 3 (Tugas 1–3)

**Peran:** Infrastructure/Platform Engineer — Ale Perdana Putra Darmawan (3126640016)
**Kelompok 3 DevOps** · Workshop DevSecOps — Evaluasi Tengah Semester
**Lingkup:** Tugas 1 (lingkungan Docker), Tugas 2 (hardening container), Tugas 3 (policy admission & isolasi jaringan)

---

## 1. Ringkasan

Repo `Kelompok3_DevOps` sebelumnya belum memiliki artefak operasional apa pun:
tidak ada `Dockerfile`, tidak ada `docker-compose.yml`, dan tidak ada konfigurasi
web server. Akibatnya aplikasi DSS belum dapat dijalankan dan Gate 4 Security
(`check-infra-policy.sh`) berjalan tanpa bahan periksa.

Pekerjaan ini menghasilkan lingkungan deployment berbasis Docker & Docker Compose
yang **mengimplementasikan langsung standar yang ditetapkan Security Engineer**
(berkas `docs/SEC-ENG/policy/`) dan tidak menyentuh kode aplikasi milik Developer.
Seluruh artefak diletakkan di `docs/Infra/` mengikuti pola `docs/PO`, `docs/Dev`,
dan `docs/SEC-ENG`.

Hasil yang sudah dapat dibuktikan tanpa menjalankan container:

- `docker compose config -q` → berkas Compose valid dan seluruh variabel ter-interpolasi.
- `check-infra-policy.sh` → **semua pemeriksaan lolos** (T-05, T-06, T-07, T-10, T-11).
- `docker compose config` → hanya service `proxy` yang memiliki published port.
- Sintaks seluruh skrip shell valid (`bash -n`), sertifikat development berhasil dibuat dan terverifikasi SAN-nya.

Langkah build/run sengaja **tidak dieksekusi** pada sesi ini; seluruh perintahnya
beserta hasil yang diharapkan tersedia di [panduan-build-run.md](./panduan-build-run.md)
agar dapat dijalankan dan dibuktikan sendiri oleh pemilik peran Infra.

---

## 2. Keterkaitan dengan Peran Lain

| Sumber | Yang dipakai Infra |
| :--- | :--- |
| PO — `docs/PO/1.3. Task-Role.md` | Empat tugas Infra; struktur repositori standar; batas "tidak mengubah kode Developer" |
| PO — `docs/PO/1.2 Risk.md` | Zero Tolerance: kredensial bocor, CVE Critical, SQLi, privilege container; kewajiban read-only filesystem bila memungkinkan |
| PO — `docs/PO/1.1. Architecture.md` | Backend REST, frontend web, database relasional, packaging multi-container |
| Security — `policy/baseline/01-tls-baseline.md` | TLS-1…TLS-9 |
| Security — `policy/baseline/02-exposure-control.md` | Matriks port, EXP-1…EXP-8, header wajib, contoh fragmen Compose |
| Security — `policy/baseline/03-logging-minimum.md` | LOG-1…LOG-5, field minimum access log, larangan isi log, retensi |
| Security — `policy/scripts/check-infra-policy.sh` | Gate 4 yang harus dilewati deployment |
| Security — `policy/scripts/verify-deployment.sh` | Skrip evidence setelah deployment |
| Security — `docs/SEC-ENG/Threat-Modelling-V1.md` | Ancaman T-02…T-11 yang menjadi dasar prioritas kontrol |

---

## 3. Dasar Teori yang Diterapkan

Materi `devsecops/bab-01.md` s.d. `bab-04.md` dipakai sebagai rujukan keputusan,
bukan sebagai tempelan:

| Konsep (bab) | Penerapan konkret di `docs/Infra/` |
| :--- | :--- |
| *Security gate sebagai keputusan kebijakan*, *Evidence as product* (Bab 1) | `smoke-test.sh` menyebut kode kontrol pada setiap pemeriksaan; `check-infra-policy.sh` dijadikan bagian dari rutinitas verifikasi, bukan checklist terpisah |
| *Shift-left* (Bab 1) | Kebijakan diperiksa secara statis sebelum container dijalankan (`docker compose config -q`, Gate 4), sehingga kesalahan konfigurasi ketahuan lebih awal |
| *Supply chain* (Bab 1) | Base image di-pin (`php:8.3-fpm-alpine`, `nginx:1.27-alpine`, `mysql:8.0`, `node:24-alpine`); build memakai `composer.lock` dan `package-lock.json` |
| *Multi-stage build* (Bab 2) | Toolchain build (composer, Node) tidak masuk image akhir → image lebih kecil, attack surface lebih sempit |
| *Model keamanan container* (Bab 2) | `USER` non-root, `cap_drop: ALL`, `no-new-privileges`, `read_only` + tmpfs, batas resource |
| *Network sebagai graf keterjangkauan* (Bab 3) | Dua network: `public` dan `internal` dengan `internal: true`; `db` dan `app` hanya di `internal` |
| *Lifecycle data* (Bab 3) | Named volume untuk data MySQL dan `storage/` Laravel; tmpfs untuk data sementara |
| *Dependency, healthcheck, readiness* (Bab 3) | `depends_on: service_healthy` untuk `app`→`db` dan `proxy`→`app`; `start_period` longgar untuk initdb |
| *Web service sebagai boundary* (Bab 4) | Nginx sebagai satu-satunya pintu masuk (origin statis + reverse proxy) |
| *TLS dan siklus hidup sertifikat* (Bab 4) | Sertifikat dibuat skrip, private key tidak masuk Git, jalur produksi (CA tepercaya) didokumentasikan terpisah |
| *Logging sebagai evidence* (Bab 4) | Access log JSON ke stdout dengan `req_id` dan `remote_addr` agar bisa dikorelasikan dengan log aplikasi (semua layanan memakai UTC) |

---

## 4. Hasil per Tugas

### Tugas 1 — Lingkungan Docker & Docker Compose

Tiga service, dua network, dua volume:

| Service | Image | Network | Published port | Peran |
| :--- | :--- | :--- | :--- | :--- |
| `proxy` | build dari `docker/proxy/Dockerfile` (berbasis `nginx:1.27-alpine`) | `public` + `internal` | `80:8080`, `443:8443` | Pintu masuk, terminasi TLS, penyaji frontend, reverse proxy `/api` |
| `app` | build dari `docker/app/Dockerfile` (berbasis `php:8.3-fpm-alpine`) | `internal` | — | Laravel REST API |
| `db` | `mysql:8.0` | `internal` | — | Basis data `classicmodels` |

Inisialisasi data: dump milik Developer di-mount **read-only** ke
`/docker-entrypoint-initdb.d/10-classicmodels.sql`, sehingga tabel dan data
terbentuk otomatis pada pembuatan volume pertama. Tidak ada berkas Developer
yang disalin atau diubah.

Pemetaan port sengaja membuat container Nginx mendengarkan `8080`/`8443`
(bukan 80/443) agar prosesnya dapat berjalan tanpa hak root, sementara pengguna
tetap mengakses port standar lewat pemetaan host.

### Tugas 2 — Hardening Container

| Kontrol | Implementasi |
| :--- | :--- |
| Base image minimal | `alpine` untuk PHP, Nginx, dan Node |
| Versi ter-pin | `php:8.3-fpm-alpine`, `nginx:1.27-alpine`, `mysql:8.0`, `node:24-alpine`, `composer:2` |
| Non-root | `USER www-data` (app), `USER nginx` (proxy) — diverifikasi Gate 4 |
| Tanpa toolchain build di image akhir | Multi-stage: stage `vendor` (composer) dan stage `web` (Node) dibuang setelah build |
| Dependensi produksi saja | `composer install --no-dev` → sekaligus memenuhi EXP-4 (paket debug tidak ikut ke image) |
| Tanpa secret di image | `rm -f .env` pada build; seluruh kredensial datang dari environment runtime |
| Tanpa mode debug | `APP_DEBUG=false`; `display_errors=Off`, `log_errors=On`, `expose_php=Off` |
| Capability diminimalkan | `cap_drop: ALL`, `security_opt: no-new-privileges:true` |
| Filesystem immutable | `read_only: true` pada `app` dan `proxy`; penulisan dialihkan ke tmpfs/named volume |
| Batas resource | `deploy.resources.limits` per service, `pm.max_children`, `client_max_body_size`, `fastcgi_read_timeout` |
| Retensi log | Driver `json-file` dengan `max-size: 10m`, `max-file: 5` |

### Tugas 3 — Policy Admission & Isolasi Jaringan

Isolasi:

- `internal: true` pada network `internal` berarti tidak ada rute masuk maupun
  keluar dari host/internet untuk network tersebut. Ini kontrol yang lebih kuat
  daripada sekadar menghapus `ports`, karena tetap berlaku walaupun konfigurasi
  service berubah.
- Hanya `proxy` yang juga tersambung ke network `public`.

Policy admission pada lapisan web (Nginx) — mengikuti `02-exposure-control.md`:

| Kontrol | Implementasi |
| :--- | :--- |
| EXP-1 | `if ($request_method !~ ^(GET\|HEAD)$) { return 405; }` |
| EXP-3 | Blok `/.`, `/storage/`, `/vendor/`, `/database/`, `/tests/`, `/bootstrap/`, `/composer.*`, `/artisan`, `/phpunit.xml`, `/package*.json`, `/telescope`, `/horizon`, `/_ignition`, `/_debugbar`, `/phpinfo.php` → 404 |
| EXP-5 | `limit_req zone=axon_rl rate=10r/s burst=20` → 429 |
| EXP-8 | `server_tokens off`, `expose_php=Off`, `fastcgi_hide_header X-Powered-By`, `SERVER_SOFTWARE` tidak diteruskan |
| Header wajib | HSTS, `X-Content-Type-Options`, `X-Frame-Options: DENY`, `Referrer-Policy`, `Permissions-Policy`, CSP |
| LOG-1..LOG-3 | `log_format axon_json` ke stdout; `$uri` dipakai (bukan `$request_uri`) agar query string tidak tercatat |

Satu pengetatan di luar contoh baseline: `Content-Security-Policy` memakai
`'self'` saja tanpa `cdn.jsdelivr.net` dan tanpa `'unsafe-inline'` pada
`style-src`. Alasannya baseline 2.3 sendiri meminta CSP "disesuaikan dengan
sumber aset sebenarnya", dan hasil build frontend membundel seluruh aset secara
lokal. Bila Developer kelak menambahkan aset CDN, CSP harus dibuka kembali untuk
origin tersebut (dan disertai SRI agar T-11 tetap lolos).

---

## 5. Temuan Penting: Dump Database adalah MySQL, bukan PostgreSQL

Dokumen arsitektur PO menyebut **PostgreSQL**, dan berkas dump diberi nama
`axon-postgresql.sql`. Namun isi berkasnya menunjukkan sebaliknya:

| Pemeriksaan | `database/axon-postgresql.sql` | `app/backend/fixed-postgres.sql` |
| :--- | :--- | :--- |
| Karakter quoting | 123 kemunculan backtick (`` `customers` ``) | 0 backtick (memakai `"customers"`) |
| Sintaks khas MySQL | `ENGINE=`, `AUTO_INCREMENT`, `int(11)` | masih `int(11)` |
| Sintaks khas PostgreSQL | tidak ada (`SERIAL`, `CREATE TYPE`, `::` tidak ditemukan) | tidak ada |
| Prosedur/trigger MySQL | ada (`DELIMITER`, `/*!...*/`) | — |

Kesimpulan:

1. `database/axon-postgresql.sql` **adalah dump MySQL** (dump standar
   `classicmodels`) meskipun namanya menyebut PostgreSQL — termasuk memuat
   `CREATE DATABASE classicmodels` dan `USE classicmodels`.
2. `app/backend/fixed-postgres.sql` adalah percobaan konversi yang **tidak
   valid untuk PostgreSQL**, karena tipe seperti `int(11)` bukan sintaks
   PostgreSQL. Inilah penyebab Developer melaporkan "tidak bisa" memakai
   PostgreSQL.
3. Dump tersebut **berisi data**, bukan hanya skema: 8 tabel (`customers`,
   `employees`, `offices`, `orderdetails`, `orders`, `payments`, `productlines`,
   `products`) dengan pernyataan `insert into … values` pada baris 54 s.d. 4065
   (total 4.065 baris).

Keputusan: environment memakai **MySQL 8.0** dengan dump apa adanya. Versi
di-pin ke `8.0` karena dump memakai *display width* (`int(11)`) yang sudah
usang. Bila impor gagal pada versi tersebut, alternatif yang sudah disiapkan
adalah `mariadb:11`.

**Tindak lanjut (handoff ke Security Engineer):** kebijakan yang ada masih
mengasumsikan PostgreSQL — `02-exposure-control.md` (matriks port) menyebut
`postgres:16-alpine` dan port `5432`, `01-tls-baseline.md` menyebut `sslmode`,
serta `verify-deployment.sh` menguji port `5432`. Perubahan engine ini perlu
dituangkan pada Threat Modeling v2/baseline agar kontrol dan skrip evidence
konsisten dengan implementasi.

---

## 6. Status Verifikasi

Sesuai kesepakatan, build/run tidak dieksekusi pada sesi penyusunan. Karena itu
laporan ini memisahkan apa yang **sudah dibuktikan** dari apa yang **menunggu
dijalankan**.

| # | Pemeriksaan | Cara | Status |
| :-: | :--- | :--- | :--- |
| 1 | Berkas Compose valid & variabel ter-interpolasi | `docker compose config -q` | ✅ terbukti |
| 2 | Hanya `proxy` yang punya published port | `docker compose config --format json` | ✅ terbukti |
| 3 | `internal: true` pada network internal | idem | ✅ terbukti |
| 4 | `read_only: true` pada `app` & `proxy` | idem | ✅ terbukti |
| 5 | Gate 4 (T-05, T-06, T-07, T-10, T-11) | `check-infra-policy.sh docs/Infra/docker-compose.yml` | ✅ lolos |
| 6 | Pemeriksaan T-02 (raw query berinterpolasi) pada kode Developer | `check-infra-policy.sh` dijalankan dari root aplikasi | ✅ lolos |
| 7 | Sintaks seluruh skrip shell | `bash -n` pada 4 skrip | ✅ terbukti |
| 8 | Sertifikat development & SAN-nya | `openssl x509 -noout -subject -ext subjectAltName -dates` | ✅ terbukti |
| 9 | Image dapat dibangun | `docker compose build` | ⏳ menunggu dijalankan |
| 10 | Stack berjalan & semua service `healthy` | `docker compose up -d` + `docker compose ps` | ⏳ menunggu dijalankan |
| 11 | API mengembalikan data (`> 0`) | `curl -k https://localhost/api/dashboard/summary` | ⏳ menunggu dijalankan |
| 12 | Perilaku TLS, header, 405/404, isolasi port, non-root | `smoke-test.sh`, `verify-deployment.sh` | ⏳ menunggu dijalankan |

Perintah lengkap beserta hasil yang diharapkan ada di
[panduan-build-run.md](./panduan-build-run.md) bagian 5 dan 6.

---

## 7. Analisis Risiko

### 7.1 Pre-Risk (teridentifikasi sebelum deployment)

| Kode | Risiko | Kontrol yang dipasang |
| :--- | :--- | :--- |
| PR-1 | Database terekspos ke host (T-05) | `internal: true` + tanpa `ports` pada `db` |
| PR-2 | Kredensial ter-hardcode (T-06) | Seluruh kredensial dari `${VAR}`; `.env` di-gitignore; `rm -f .env` saat build |
| PR-3 | Pesan error verbose ke client (T-07) | `APP_DEBUG=false`, `display_errors=Off`, `expose_php=Off` |
| PR-4 | Container berjalan sebagai root (T-10) | `USER` non-root pada kedua image; diverifikasi Gate 4 |
| PR-5 | Banjir request / resource exhaustion (T-08, T-09) | `limit_req`, batas CPU/RAM, `pm.max_children`, timeout FastCGI |
| PR-6 | Mixed content & CORS | Frontend satu origin dengan API; `VITE_API_URL=/api` |
| PR-7 | Sertifikat development dipakai di produksi | Diberi label tegas pada skrip dan README; jalur CA tepercaya didokumentasikan |

### 7.2 Residual Risk

| Kode | Risiko tersisa | Alasan masih ada | Mitigasi lanjutan |
| :--- | :--- | :--- | :--- |
| RR-1 | Sertifikat self-signed belum dipercaya browser | Kebutuhan pengujian Milestone; tidak ada domain publik | Terbitkan sertifikat CA (mis. Let's Encrypt) saat VPS/domain siap |
| RR-2 | Tidak ada pemindaian image pada pipeline | Tugas 4 (CI) belum dikerjakan | Gate 5 Trivy menyusul pada fase CI |
| RR-3 | Kolom sensitif dapat muncul di respons API (EXP-7) | Berada di kode aplikasi, bukan ranah Infra | Handoff ke Developer |
| RR-4 | Query lambat belum dicatat (LOG-4) | Berada di kode aplikasi | Handoff ke Developer |
| RR-5 | Monitoring/alert belum ada | 03-logging-minimum 3.6 menugaskan Platform, tetapi belum dijadwalkan | Tambahkan alert 5xx/429/404 dan restart container berulang pada iterasi berikutnya |
| RR-6 | Backup & uji restore volume belum diuji | Belum termasuk lingkup Milestone 3 | Latihan backup/restore `db-data` (pola Bab 3) sebelum presentasi |

### 7.3 Handoff ke Peran Lain

| Untuk | Item | Alasan |
| :--- | :--- | :--- |
| Security Engineer | Selaraskan baseline & skrip evidence dari PostgreSQL ke MySQL (`02-exposure-control.md`, `01-tls-baseline.md`, `verify-deployment.sh` yang menguji port `5432`) | Engine berubah sesuai bukti pada bagian 5 |
| Security Engineer | `verify-deployment.sh` menerima argumen `DB_HOST`, tetapi daftar port yang diuji masih `5432`/`9000`; tambahkan `3306` | Agar uji isolasi database benar-benar menguji MySQL |
| Developer | `TrustProxies` belum diatur (`bootstrap/app.php` masih kosong) | TLS-7 (`Laravel sadar proxy`). Dampak saat ini kecil karena Nginx mengirim skema HTTPS lewat FastCGI, tetapi tetap perlu ditetapkan bila topologi berubah |
| Developer | EXP-6 (whitelist parameter filter), EXP-7 (kolom sensitif), LOG-4 (query lambat) | Berada di kode aplikasi |
| PO | Konfirmasi perubahan engine ke MySQL dan status read-only filesystem (bukan hanya `if possible`) | Mengubah asumsi dokumen arsitektur/risiko |
| Seluruh tim | Peletakan `docker-compose.yml` di `docs/Infra/` menuntut penyesuaian path pada fase CI: Gate 4 perlu diarahkan ke berkas ini (`bash docs/SEC-ENG/policy/scripts/check-infra-policy.sh docs/Infra/docker-compose.yml`), dan Gate 5 tidak dapat memakai pola "build per-Dockerfile" karena konteks build kedua image adalah folder `docs/` | Perlu diputuskan bersama saat Tugas 4 dikerjakan |

---

## 8. Rekomendasi untuk Environment Production-like

1. **Sertifikat CA tepercaya.** Ganti `certs/` self-signed dengan sertifikat CA
   dan automatisasi pembaruan; pisahkan private key ke secret/mount read-only.
2. **Manajemen secret.** Pindahkan `.env` ke secret manager (Docker secrets,
   Azure Key Vault, atau sejenisnya) agar tidak ada kredensial pada berkas host.
3. **Tag image dengan digest.** Setelah pipeline berjalan, deploy memakai
   `image@sha256:…` alih-alih tag, agar artefak yang diuji sama dengan yang
   dijalankan (provenance).
4. **Scanning berkala.** Jalankan Trivy pada image dan `composer.lock`, serta
   `composer audit`, dengan kebijakan gagal pada CRITICAL sesuai risk tolerance PO.
5. **Monitoring & alert.** Aktifkan alert 5xx, 429/405, probing 404 dari satu IP,
   dan container yang restart berulang (kriteria 03-logging-minimum 3.6).
6. **Backup dan uji restore.** Jalankan latihan restore volume `db-data`
   berkala; dokumentasikan hasilnya sebagai evidence, bukan hanya prosedur.
7. **Pengiriman log terpusat.** Alihkan driver `json-file` ke pengumpul log
   terpusat dengan retensi minimal 30 hari agar log tidak bergantung pada host.
8. **Perketat `cap_drop` pada database.** Saat ini `db` hanya memakai
   `no-new-privileges` karena proses inisialisasi MySQL memerlukan capability
   tertentu; pada produksi perlu diuji penurunan bertahap mengikuti hasil audit.
9. **Branch protection & review.** Pastikan perubahan `docs/Infra/` juga melalui
   review dua orang dan pipeline hijau — konfigurasi proxy diperlakukan sebagai
   kode (Bab 4: tata kelola perubahan).

---

## 9. Lampiran

### 9.1 Daftar artefak

| Berkas | Tugas |
| :--- | :---: |
| `docs/Infra/docker-compose.yml` | 1 |
| `docs/Infra/.env.example`, `docs/Infra/.gitignore`, `docs/.dockerignore` | 1 |
| `docs/Infra/docker/app/Dockerfile`, `php.ini`, `zz-axon-fpm.conf`, `entrypoint.sh` | 1, 2 |
| `docs/Infra/docker/proxy/Dockerfile`, `nginx.conf` | 2, 3 |
| `docs/Infra/scripts/gen-certs.sh`, `up.sh`, `smoke-test.sh` | 1, 2, 3 |
| `docs/Infra/README.md`, `docs/Infra/docs/panduan-build-run.md`, `docs/Infra/docs/laporan-infra.md` | Dokumentasi |

### 9.2 Perintah pembuktian (dijalankan dari root repositori)

```bash
# 1. Validasi konfigurasi (tanpa menjalankan container)
docker compose -f docs/Infra/docker-compose.yml config -q

# 2. Gate 4 milik Security Engineer
bash docs/SEC-ENG/policy/scripts/check-infra-policy.sh docs/Infra/docker-compose.yml

# 3. Setelah stack dijalankan
bash docs/Infra/scripts/smoke-test.sh

# 4. Evidence resmi dari Security Engineer
DEV_INSECURE=1 EVIDENCE_DIR=docs/Infra/evidence \
  bash docs/SEC-ENG/policy/scripts/verify-deployment.sh https://localhost
```

### 9.3 Ringkasan keluaran Gate 4 yang sudah diperoleh

```text
[OK] T-05: service database tidak mem-publish port ke host
[OK] T-06: tidak ada password/APP_KEY literal di docs/Infra/docker-compose.yml
[OK] T-07: APP_DEBUG tidak aktif di docs/Infra/docker-compose.yml
[OK] T-10: ./docs/Infra/docker/app/Dockerfile memakai USER www-data
[OK] T-10: ./docs/Infra/docker/proxy/Dockerfile memakai USER nginx
[OK] T-06: .env tidak ter-track di Git
[OK] T-11: semua aset CDN memakai SRI (atau tidak ada aset CDN)
```
