# Laporan Infra — Milestone 3 (Tugas 1–4)

**Peran:** Infrastructure/Platform Engineer — Ale Perdana Putra Darmawan (3126640016)
**Kelompok 3 DevOps** · Workshop DevSecOps — Evaluasi Tengah Semester
**Lingkup:** Tugas 1 (lingkungan Docker), Tugas 2 (hardening container),
Tugas 3 (policy admission & isolasi jaringan), Tugas 4 (otomasi pipeline & gate)
**Revisi terakhir:** menyesuaikan perintah baru PO pada `docs/PO/2.1 Developer Analysis Result.md`,
commit `0fdf90b` (bagian "Status Implementasi DevSecOps" pada `README.md`), dan
butir backlog PO (aktivasi pipeline, SBOM, laporan audit)

---

## 1. Ringkasan

Repo `Kelompok3_DevOps` sebelumnya belum memiliki artefak operasional apa pun:
tidak ada `Dockerfile`, tidak ada `docker-compose.yml`, dan tidak ada konfigurasi
web server. Akibatnya aplikasi DSS belum dapat dijalankan dan Gate 4 Security
(`check-infra-policy.sh`) berjalan tanpa bahan periksa.

Pekerjaan ini menghasilkan lingkungan deployment berbasis Docker & Docker Compose
yang **mengimplementasikan langsung standar yang ditetapkan Security Engineer**
(berkas `docs/SEC-ENG/policy/`) dan tidak menyentuh kode aplikasi milik Developer.
Seluruh artefak diletakkan di `docs/INFRA/` mengikuti pola `docs/PO`, `docs/Dev`,
dan `docs/SEC-ENG`.

Hasil yang sudah dapat dibuktikan tanpa menjalankan container:

- `docker compose config -q` → berkas Compose valid dan seluruh variabel ter-interpolasi.
- `check-infra-policy.sh` → **semua pemeriksaan lolos** (T-05, T-06, T-07, T-10, T-11).
- `docker compose config` → hanya service `proxy` yang memiliki published port.
- Sintaks seluruh skrip shell valid (`bash -n`), sertifikat development berhasil dibuat dan terverifikasi SAN-nya.

Langkah build/run sengaja **tidak dieksekusi** pada sesi ini; seluruh perintahnya
beserta hasil yang diharapkan tersedia di [panduan-build-run.md](./panduan-build-run.md)
agar dapat dijalankan dan dibuktikan sendiri oleh pemilik peran Infra.

### 1.1 Perubahan pada revisi ini

| # | Perubahan | Pemicu |
| :-: | :--- | :--- |
| 1 | **PHP 8.3 → 8.4** pada image backend, dan stage vendor tidak lagi memakai PHP bawaan image `composer:2` | Bug pada artefak sendiri: `composer.lock` mensyaratkan `php >= 8.4.1` (lihat §6.1) |
| 2 | Rename `docs/Infra` → `docs/INFRA` (termasuk seluruh rujukan path) | Struktur resmi pada `README.md` repositori |
| 3 | Network `internal`/`public` → **`axon-network`**/`axon-public` | Arahan PO pada `2.1 Developer Analysis Result.md` bagian 6 |
| 4 | User database aplikasi `dss_user` **hanya `SELECT`**, ditegakkan dan diverifikasi skrip initdb | Arahan PO pada `1.1. Architecture.md` (Data Tier) |
| 5 | Pemeriksaan CORS ketat + hak akses database di `smoke-test.sh` | `1.1. Architecture.md` (Application Tier) |
| 6 | **Tugas 4**: pipeline Security Gate di `.github/workflows/`, Dependabot, skrip gate lokal, skrip SBOM | Tugas 4 role Infra + Prioritas P1 PO (SBOM belum ada) |
| 7 | MySQL ditandai **Resolved** | PO telah menyelaraskan `1.1. Architecture.md` ke MySQL 8.x |
| 8 | Workflow dinamai **`ci.yml`** (dari `security-gate.yml`) | Butir 1 backlog PO pada `README.md` menunjuk path itu secara eksplisit |
| 9 | Gate lokal menghasilkan laporan **SARIF + JSON**, bukan hanya log teks | Butir 3 backlog PO meminta laporan berformat SARIF/JSON |
| 10 | Crosscheck klaim README PO ditambahkan sebagai §3, termasuk 2 ketidaksesuaian yang perlu dikoreksi PO/Developer | Commit `0fdf90b Refactoring README.md` menambah bagian "Status Implementasi DevSecOps" |

---

## 2. Keterkaitan dengan Peran Lain

| Sumber | Yang dipakai Infra |
| :--- | :--- |
| PO — `docs/PO/1.3. Task-Role.md` | Empat tugas Infra; struktur repositori standar; batas "tidak mengubah kode Developer" |
| PO — `docs/PO/1.2 Risk.md` | Zero Tolerance: kredensial bocor, CVE Critical, SQLi, privilege container; kewajiban read-only filesystem bila memungkinkan |
| PO — `docs/PO/1.1. Architecture.md` | Stack final (React 19/Vite 8, Laravel 13 di **PHP 8.4**, **MySQL 8.x/MariaDB 10.4+**); Data Tier: user aplikasi **hanya SELECT**, port 3306 dilarang diekspos; Application Tier: CORS ketat |
| PO — `docs/PO/2.1 Developer Analysis Result.md` | Arahan langsung Infra (§6): `mysql:8.0`/`mariadb:10.4` pada jaringan privat **`axon-network`**, tanpa ekspos port. Prioritas P1: SBOM belum ada |
| PO — `README.md` repositori | Struktur resmi: `.github/workflows` di root, `docs/INFRA/` untuk artefak Infra |
| Security — `policy/baseline/01-tls-baseline.md` | TLS-1…TLS-9 |
| Security — `policy/baseline/02-exposure-control.md` | Matriks port, EXP-1…EXP-8, header wajib, contoh fragmen Compose |
| Security — `policy/baseline/03-logging-minimum.md` | LOG-1…LOG-5, field minimum access log, larangan isi log, retensi |
| Security — `policy/scripts/check-infra-policy.sh` | Gate 4 yang harus dilewati deployment |
| Security — `policy/scripts/verify-deployment.sh` | Skrip evidence setelah deployment |
| Security — `docs/SEC-ENG/Threat-Modelling-V1.md` | Ancaman T-02…T-11 yang menjadi dasar prioritas kontrol |

---

## 3. Crosscheck dengan README Po (commit `0fdf90b`)

PO menambahkan bagian **"Status Implementasi DevSecOps"** pada `README.md`
(commit `0fdf90b Refactoring README.md`, +75 baris). Berikut hasil pemeriksaan
silang antara klaim dokumen tersebut dengan kondisi nyata repositori.

### 3.1 Klaim PO tentang Infra — semuanya terverifikasi

| Klaim PO pada README.md | Verifikasi | Status |
| :--- | :--- | :---: |
| Orkestrasi multi-kontainer `docs/INFRA/docker-compose.yml` | Berkas ada; 3 service, 2 network, 2 volume | ✅ |
| Dockerfile backend non-root `www-data`, ekstensi PDO terisolasi | `USER www-data`; hanya `mbstring`, `pdo_mysql`, `opcache` yang dipasang | ✅ |
| Dockerfile Nginx + template pengerasan `nginx.conf` | Berkas ada; kebijakan TLS/EXP/LOG diterapkan | ✅ |
| Skrip `gen-certs.sh` dan `smoke-test.sh` | Keduanya ada dan tervalidasi sintaks | ✅ |
| Dokumentasi di `docs/INFRA/README.md` | Ada, dengan diagram arsitektur dan tabel keputusan | ✅ |
| Scorecard: *Container Hardening Specs* 🟢 Selesai | Benar; diverifikasi ulang oleh `check-infra-policy.sh` (T-10 lolos pada kedua Dockerfile) | ✅ |

Penulisan `docs/INFRA` (huruf besar) pada README **cocok** dengan implementasi.

### 3.2 Butir backlog PO yang sudah/akan tertutup oleh pekerjaan ini

| Butir backlog PO | Kondisi sebelum | Kondisi setelah pekerjaan ini |
| :--- | :--- | :--- |
| **1. Aktivasi pipeline CI/CD di `.github/workflows/`** (prioritas utama) | Belum ada; hanya template di `docs/SEC-ENG/policy/pipeline/` | ✅ `.github/workflows/ci.yml` — 6 gate, action dipin ke SHA, 4 masalah path pada template ditambal |
| **2. SBOM CycloneDX `backend-sbom.cdx.json` + `frontend-sbom.cdx.json`** | Belum ada berkas maupun foldernya | ✅ `scripts/generate-sbom.sh` menghasilkan **nama berkas yang persis sama** seperti yang diminta PO |
| **3. Laporan audit SARIF/JSON ke `docs/SEC-ENG/reports/`** | Folder belum ada; belum ada laporan mesin-terbaca | ✅ `run-gates-local.sh` kini menghasilkan `gitleaks.sarif`, `trivy-fs.sarif`, dan `trivy-fs.json`; arahkan `REPORTS_DIR=docs/SEC-ENG/reports` |

Catatan kepatuhan nama berkas: PO menulis `.github/workflows/ci.yml`, sehingga
workflow **dinamai `ci.yml`** (bukan `security-gate.yml` seperti nama template)
agar dokumen dan repositori menunjuk berkas yang sama. Nama workflow di dalamnya
tetap `security-gate` karena itulah yang bermakna di tab Actions.

### 3.3 Ketidaksesuaian yang ditemukan pada dokumen PO

Ini disampaikan apa adanya karena dokumen yang tidak akurat akan menyesatkan
pembaca berikutnya, termasuk saat presentasi.

| # | Klaim pada README.md | Kenyataan | Tingkat |
| :-: | :--- | :--- | :--- |
| 1 | Developer menyediakan skrip launcher `run-all.bat`, `run-backend.bat`, `run-frontend.bat` | **Ketiga berkas itu tidak ada di repositori.** Yang ada hanya `app/backend/artisan.bat` dan `app/backend/php.bat` (sisa `php.bat` juga masih menunjuk path absolut lokal Developer: `D:\php84\php.exe`) | 🟠 Perlu dikoreksi |
| 2 | Struktur repositori menulis `docs/DEV/` | Folder nyatanya `docs/Dev` (huruf kecil). Hanya `docs/INFRA` yang sudah disamakan, sesuai keputusan | 🟡 Kosmetik, tetapi memengaruhi path di skrip/CI |
| 3 | Scorecard: *Automated CI/CD Pipeline* 🟡 Parsial — "belum dipasang ke `.github/workflows/`" | Benar saat ditulis. Setelah commit pekerjaan ini, statusnya menjadi 🟢 | 🟡 Perlu pembaruan status |
| 4 | Scorecard: *Software Bill of Materials* 🔴 Belum | Benar saat ditulis; skrip pembuatnya sudah tersedia, tinggal dijalankan | 🟡 Perlu pembaruan status |
| 5 | Butir backlog 3 menulis laporan ke `docs/SEC-ENG/reports/`, sedangkan struktur folder menaruh `reports/` di bawah `docs/SEC-ENG/` — memang konsisten, tetapi `1. Project-Overview.md` menaruh `reports/` dan `sbom/` di **root** repositori | Ada dua definisi lokasi yang berbeda antar dokumen PO | 🟡 Perlu penegasan |
| 6 | Butir backlog 2 menulis SBOM di "folder `/sbom`" tanpa path lengkap | Struktur folder pada README mengarah ke `docs/Dev/axon-devsecops-dss/sbom/`, dan skrip Infra menulis ke sana | 🟡 Perlu penegasan |

**Usulan penegasan lokasi (agar tidak ada dua tafsir):**

| Artefak | Usulan lokasi | Alasan |
| :--- | :--- | :--- |
| SBOM | `docs/Dev/axon-devsecops-dss/sbom/` | Sesuai blok struktur pada README; berada di dalam pohon aplikasi seperti dokumen lain |
| Laporan scan (SARIF/JSON) | `docs/SEC-ENG/reports/` | Sesuai butir backlog 3 dan blok struktur README |

### 3.4 Butir backlog PO yang BUKAN ranah Infra

| Butir | Pemilik | Catatan untuk Infra |
| :--- | :--- | :--- |
| 4. Uji coba integrasi kontainer runtime | Infra | **Tidak dijalankan pada sesi ini** (kesepakatan: tanpa build/run). Perintah lengkap ada di [panduan-build-run.md](./panduan-build-run.md); jaringan `axon-network` sudah sesuai yang disebut PO |
| 5. Penyempurnaan Modul Bisnis DSS (Order Fulfillment, Inventory Health) | Developer | Infra hanya menyediakan jalur deploy; kode tidak disentuh |
| 6. Threat Modeling v2 | Security Engineer | Infra menyediakan input: temuan §6.1 dan daftar handoff §8.3 |
| 2. (bagian Developer) generate SBOM | Developer | Infra menyediakan otomatisasinya; kepemilikan isi tetap Developer |

> **Catatan penting soal penilaian "Uji Coba Integrasi Kontainer Runtime".**
> Pada sesi penyusunan ini `docker run` tidak dapat dipakai (akses `docker.sock`
> tidak tersedia), sedangkan `docker compose config` bersifat client-side dan
> tetap berjalan. Karena itu langkah 4 belum dapat dibuktikan dan **tidak boleh
> diklaim sudah selesai**. Semua perintah beserta hasil yang diharapkan sudah
> disiapkan agar kamu dapat menjalankannya sendiri dan mengambil buktinya.

---

## 4. Dasar Teori yang Diterapkan

Materi `devsecops/bab-01.md` s.d. `bab-04.md` dipakai sebagai rujukan keputusan,
bukan sebagai tempelan:

| Konsep (bab) | Penerapan konkret di `docs/INFRA/` |
| :--- | :--- |
| *Security gate sebagai keputusan kebijakan*, *Evidence as product* (Bab 1) | `smoke-test.sh` menyebut kode kontrol pada setiap pemeriksaan; `check-infra-policy.sh` dijadikan bagian dari rutinitas verifikasi, bukan checklist terpisah |
| *Shift-left* (Bab 1) | Kebijakan diperiksa secara statis sebelum container dijalankan (`docker compose config -q`, Gate 4), sehingga kesalahan konfigurasi ketahuan lebih awal |
| *Supply chain* (Bab 1) | Base image di-pin (`php:8.4-fpm-alpine`, `nginx:1.27-alpine`, `mysql:8.0`, `node:24-alpine`); action di-pin ke commit SHA; build memakai `composer.lock` dan `package-lock.json` |
| *Multi-stage build* (Bab 2) | Toolchain build (composer, Node) tidak masuk image akhir → image lebih kecil, attack surface lebih sempit |
| *Model keamanan container* (Bab 2) | `USER` non-root, `cap_drop: ALL`, `no-new-privileges`, `read_only` + tmpfs, batas resource |
| *Network sebagai graf keterjangkauan* (Bab 3) | Dua network: `public` dan `internal` dengan `internal: true`; `db` dan `app` hanya di `internal` |
| *Lifecycle data* (Bab 3) | Named volume untuk data MySQL dan `storage/` Laravel; tmpfs untuk data sementara |
| *Dependency, healthcheck, readiness* (Bab 3) | `depends_on: service_healthy` untuk `app`→`db` dan `proxy`→`app`; `start_period` longgar untuk initdb |
| *Web service sebagai boundary* (Bab 4) | Nginx sebagai satu-satunya pintu masuk (origin statis + reverse proxy) |
| *TLS dan siklus hidup sertifikat* (Bab 4) | Sertifikat dibuat skrip, private key tidak masuk Git, jalur produksi (CA tepercaya) didokumentasikan terpisah |
| *Logging sebagai evidence* (Bab 4) | Access log JSON ke stdout dengan `req_id` dan `remote_addr` agar bisa dikorelasikan dengan log aplikasi (semua layanan memakai UTC) |

---

## 5. Hasil per Tugas

### Tugas 1 — Lingkungan Docker & Docker Compose

Tiga service, dua network, dua volume:

| Service | Image | Network | Published port | Peran |
| :--- | :--- | :--- | :--- | :--- |
| `proxy` | build dari `docker/proxy/Dockerfile` (berbasis `nginx:1.27-alpine`) | `axon-public` + `axon-network` | `80:8080`, `443:8443` | Pintu masuk, terminasi TLS, penyaji frontend, reverse proxy `/api` |
| `app` | build dari `docker/app/Dockerfile` (berbasis `php:8.4-fpm-alpine`) | `axon-network` | — | Laravel REST API |
| `db` | `mysql:8.0` | `axon-network` | — | Basis data `classicmodels`; user aplikasi hanya `SELECT` |

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
| Versi ter-pin | `php:8.4-fpm-alpine`, `nginx:1.27-alpine`, `mysql:8.0`, `node:24-alpine`; hanya biner composer yang diambil dari `composer:2` |
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

- `internal: true` pada network `axon-network` berarti tidak ada rute masuk
  maupun keluar dari host/internet untuk network tersebut. Ini kontrol yang lebih
  kuat daripada sekadar menghapus `ports`, karena tetap berlaku walaupun
  konfigurasi service berubah.
- Hanya `proxy` yang juga tersambung ke network `axon-public`.
- Nama `axon-network` mengikuti arahan Product Owner pada
  `docs/PO/2.1 Developer Analysis Result.md` bagian 6.

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

### Tugas 3 (lanjutan) — Least privilege database & CORS ketat

Dua kontrol ini ditambahkan setelah membaca arahan baru PO.

**1. User database hanya `SELECT`.**
`docs/PO/1.1. Architecture.md` (Data Tier) mewajibkan
`GRANT SELECT ON classicmodels.* TO 'dss_user'@'%';`. Implementasinya
`docker/db/20-app-user-privileges.sh`, dipasang ke `/docker-entrypoint-initdb.d/`
sebagai berkas nomor `20-` sehingga berjalan setelah impor skema `10-`.

| Aspek | Nilai |
| :--- | :--- |
| Urutan eksekusi | Entrypoint resmi MySQL menjalankan `docker_setup_db` (membuat DB + user + `GRANT ALL`) **sebelum** memproses berkas initdb. Urutan ini diverifikasi dari sumber resmi `docker-library/mysql` (`docker_setup_db` baris 397, `docker_process_init_files` baris 398). |
| Tindakan | `REVOKE ALL PRIVILEGES` dan `REVOKE GRANT OPTION` pada database aplikasi, lalu `GRANT SELECT`. |
| Verifikasi | `SHOW GRANTS` diperiksa; bila masih ada INSERT/UPDATE/DELETE/DROP/ALTER/CREATE, skrip keluar dengan status bukan-nol sehingga **inisialisasi database gagal dan container berhenti** (fail-closed). |
| Rahasia | Skrip tidak memuat password literal; seluruhnya dari environment container (tetap lolos T-06). |
| Konsekuensi | `php artisan migrate` tidak dapat dijalankan dengan user ini — disengaja, didokumentasikan di `panduan-build-run.md` §5.5 (Konsekuensi user database SELECT-only) beserta prosedur DDL sekali jalan memakai kredensial root. |

Fail-closed dipilih secara sadar: prinsipnya lebih baik container menolak start
daripada berjalan dalam keadaan hak berlebih. Ini juga menjadikan kontrol dapat
diaudit — status container itu sendiri adalah buktinya.

**2. CORS ketat.** `1.1. Architecture.md` (Application Tier) meminta CORS yang
hanya mengizinkan origin frontend terdaftar. Desain ini sudah satu origin
(frontend dan `/api` dilayani Nginx yang sama), sehingga CORS tidak diperlukan
sama sekali — itu sendiri adalah bentuk penegakan *deny by default*. Karena tidak
ada konfigurasi CORS, yang bisa diperiksa bukan "apakah daftar origin benar",
melainkan "apakah ada header origin yang bocor". `smoke-test.sh` memeriksa
respons tidak memuat `Access-Control-Allow-Origin: *`.

---

### Tugas 4 — Otomasi Pipeline & Gate

**Berkas:** `.github/workflows/ci.yml` (root repo) + `.github/dependabot.yml`
**Skrip pendukung:** `scripts/run-gates-local.sh`, `scripts/generate-sbom.sh`

#### Mengapa workflow berada di root, bukan di `docs/INFRA/`

GitHub Actions **hanya** membaca workflow dari `.github/workflows/` pada root
repositori. Berkas di sub-folder tidak akan pernah dieksekusi. Struktur resmi pada
`README.md` repositori juga menempatkannya di root. Karena itu pipeline berada di
root sementara seluruh konfigurasi lain tetap di `docs/INFRA/`.

#### Mengapa namanya `ci.yml`

Butir 1 backlog PO pada `README.md` menunjuk path `.github/workflows/ci.yml` secara
eksplisit, sehingga nama itu yang dipakai agar dokumen dan repositori menunjuk
berkas yang sama. Nama workflow di dalamnya tetap `security-gate` karena itulah
yang bermakna di tab Actions dan menjadi dasar penamaan job ringkasan
(`Security Gate - PASSED`) yang dipakai branch protection.

#### Pemenuhan butir backlog PO yang relevan

| Butir backlog README.md | Pemenuhan |
| :--- | :--- |
| 1. Aktivasi pipeline di `.github/workflows/` | `.github/workflows/ci.yml` — 6 gate; 4 masalah path pada template Security ditambal |
| 2. SBOM CycloneDX `backend-sbom.cdx.json` + `frontend-sbom.cdx.json` | `scripts/generate-sbom.sh` menghasilkan **nama berkas persis sama**; lokasi `docs/Dev/axon-devsecops-dss/sbom/` sesuai blok struktur README |
| 3. Laporan audit SARIF/JSON | `run-gates-local.sh` menghasilkan `gitleaks.sarif`, `trivy-fs.sarif`, `trivy-fs.json`; `REPORTS_DIR=docs/SEC-ENG/reports` untuk mengisi folder Security |

#### Gate yang diimplementasikan

| Gate | Tool | Blocking? | Ditambahkan/diubah dari template Security |
| :---: | :--- | :---: | :--- |
| 1 | Gitleaks (config milik Security) | ✅ | Ditambah unggah SARIF ke tab Security |
| 2 | SonarCloud | ⚠️ non-blocking sementara | PHP dinaikkan ke 8.4; `projectBaseDir` diarahkan ke root aplikasi |
| 3 | Trivy fs + SBOM CycloneDX | ✅ untuk CRITICAL | `--ignorefile` di-override; SBOM dihasilkan (P1 PO) |
| 4 | `check-infra-policy.sh` + Hadolint | ✅ | Ditambah Hadolint; skrip Security juga dijalankan dari root aplikasi agar T-02 benar-benar diperiksa |
| 5 | `docker compose build` + Trivy image | ✅ | Pola build diubah dari per-Dockerfile menjadi lewat Compose |
| 6 | Job ringkasan | ✅ | Satu status wajib untuk branch protection |

#### Empat masalah integrasi yang ditemukan dan ditambal

1. **Rujukan path pada template Security mengandaikan `policy/` ada di root** repositori,
   padahal nyatanya di `docs/SEC-ENG/policy/`. Seluruh path disesuaikan.
2. **`trivy.yaml` menulis `ignorefile: policy/.trivyignore`** — path itu relatif terhadap
   CWD sehingga tidak ditemukan saat dijalankan dari root repo. Di workflow maupun di
   `run-gates-local.sh`, nilainya di-override eksplisit dengan `--ignorefile`.
3. **Gate 5 pada template memakai pola build per-Dockerfile**, padahal konteks build
   kedua image adalah folder `docs/` (`build.context: ..`). Diganti menjadi
   `docker compose build`.
4. **`docker compose config` membutuhkan `.env`** karena compose memakai
   `${VAR:?...}`. Di CI dibuat `.env` dari `.env.example` yang hanya berisi nilai
   dummy (bukan rahasia), khusus untuk langkah validasi dan build.

#### Kesiapan rantai pasok (T-11)

Mitigasi T-11 diminta eksplisit oleh Security Engineer ("pin versi action ke commit SHA
sebelum produksi"). Implementasinya:

- Seluruh action di-pin ke **commit SHA**, bukan tag yang bisa dipindahkan.
- Gitleaks, Trivy, dan Hadolint dipanggil sebagai image dengan **versi ter-pin**
  (v8.28.0, 0.58.0, 2.12.0) — versi yang sama dipakai skrip gate lokal agar hasil
  lokal dan pipeline identik.
- `.github/dependabot.yml` menjaga pin tetap terbarui untuk `github-actions`, `docker`,
  dan `docker-compose`. Ini bagian penting: pinning tanpa mekanisme pembaruan akan
  berubah dari kontrol keamanan menjadi utang teknis.
- `permissions: contents: read` sebagai default; hanya job yang mengunggah SARIF yang
  menambah `security-events: write`.
- Image dipindai dari hasil `docker save` (bukan dengan memberi Trivy akses ke
  `/var/run/docker.sock`) sehingga privilege yang diberikan ke pemindai lebih sedikit.

#### Mengapa Gate 2 belum memblokir

Quality Gate `Axon-DSS-Baseline` buatan Security Engineer mensyaratkan
`new_coverage >= 70%`. Kondisi nyatanya: hanya ada dua berkas tes skeleton Laravel
(`tests/Unit/ExampleTest.php`, `tests/Feature/ExampleTest.php`, masing-masing ±350 byte)
dan **nol tes API**, sehingga coverage pasti 0% dan gate akan merah permanen terlepas
dari kualitas kode.

Keputusan yang diambil: job tetap berjalan dan melaporkan, tetapi `continue-on-error`
sehingga belum memblokir. Setelah Developer menambah tes, hapus baris itu untuk
menjadikannya gate nyata. Kondisi ini dicatat sebagai risiko residual RR-7 dan
dinyatakan terbuka — bukan disembunyikan — karena gate yang "terlihat hijau" tanpa
benar-benar memeriksa justru menciptakan rasa aman yang palsu (Bab 1).

#### Pendapat: seharusnya CI/CD diterapkan dari awal?

**Setuju sebagian, dan ada satu nuansa yang penting untuk dicatat di laporan.**

Argumen "dari awal" benar, tetapi tidak bisa diterapkan merata pada semua gate karena
adanya **ketergantungan bootstrap**:

| Gate | Butuh apa agar bisa jalan | Bisa sejak hari pertama? |
| :---: | :--- | :---: |
| 1 Secret scan | Kode + riwayat commit (sudah ada sejak commit awal) | ✅ |
| 2 SAST | Kode aplikasi (sudah ada sejak commit awal) | ✅ |
| 3 SCA + SBOM | `composer.lock` / `package-lock.json` (sudah ada sejak awal) | ✅ |
| 4 Infra policy | `docker-compose.yml` + `Dockerfile` (baru ada di Milestone 3) | ❌ |
| 5 Container scan | Image hasil build (baru ada di Milestone 3) | ❌ |

Jadi urutan yang benar bukan "semua gate di awal" atau "semua gate di akhir",
melainkan **scaffold pipeline lebih awal dengan gate yang inputnya sudah tersedia,
lalu tambahkan Gate 4 dan 5 begitu artefaknya lahir.** Gate 1–3 tidak punya alasan
untuk menunggu, karena seluruh inputnya sudah ada sejak commit pertama.

**Bukti konkret bahwa keterlambatan ini berbiaya:** bug PHP 8.3 vs Symfony 8.4.1
(§6.1) akan langsung tertangkap oleh Gate 2 atau Gate 3 pada commit pertama — job
tersebut menjalankan `composer install` dari lockfile yang sama. Karena pipeline baru
dipasang di akhir, kesalahan itu baru ketemu lewat pembacaan manual, dan enam commit
sudah terlanjur masuk tanpa pemeriksaan otomatis.

Mitigasi yang dilakukan sekarang:

1. Pipeline dipasang dan disiapkan untuk langsung aktif pada push berikutnya.
2. Perintah verifikasi disediakan agar gate dapat dijalankan pada kondisi saat ini
   (termasuk `run-gates-local.sh` untuk memeriksa seluruh riwayat).
3. Branch protection dengan required check `Security Gate - PASSED` disiapkan agar
   commit berikutnya wajib hijau — §6.3 panduan.
4. Kesenjangan ini dinyatakan terbuka di laporan, karena yang dinilai mencakup proses,
   bukan hanya hasil akhir.

---

## 6. Temuan Penting

### 6.1 Bug pada artefak sendiri: PHP 8.3 akan gagal build

Ini temuan paling penting pada revisi ini, dan sengaja ditulis lebih dulu karena
menyangkut kesalahan pada pekerjaan Infra sendiri — bukan pada peran lain.

Image backend awalnya memakai `php:8.3-fpm-alpine`. Berkas `composer.lock` milik
Developer mengunci paket berikut:

| Fakta | Nilai |
| :--- | :--- |
| `symfony/console` | **v8.1.8**, berada di `packages` (dependensi **produksi**, bukan dev) |
| Syarat PHP paket tersebut | **`>=8.4.1`** |
| Jumlah paket produksi dengan syarat `>=8.4.1` | **19 paket** (seluruh keluarga Symfony) |
| `config.platform` pada `composer.json` | **tidak diset** → tidak ada override yang memaafkan perbedaan versi |
| Konfirmasi dari sisi Developer | `app/backend/php.bat` menunjuk `D:\php84\php.exe` |

Karena `config.platform` tidak diset, `composer install` memverifikasi syarat
platform terhadap PHP yang benar-benar dipakai. Di PHP 8.3 proses berhenti dengan
*"your lock file does not contain a compatible set of packages"*, sehingga image
**tidak akan pernah** berhasil dibangun. Dokumen `1.1. Architecture.md` juga
menetapkan "Laravel 13 berbasis PHP 8.4", jadi ini konsisten dengan rencana PO.

Perbaikan yang dilakukan:

1. `ARG PHP_VERSION=8.4` dan base `php:${PHP_VERSION}-fpm-alpine`.
2. Stage `vendor` tidak lagi `FROM composer:2` (yang membawa PHP versinya sendiri,
   berpotensi berbeda dari runtime), melainkan `FROM base` dengan hanya **biner**
   composer yang disalin: `COPY --from=composer:2 /usr/bin/composer`. Dengan begitu
   penginstall dan runtime memakai PHP yang sama, dan syarat platform terbukti saat
   build — bukan diasumsikan.
3. Ditambahkan `composer check-platform-reqs --no-dev` setelah install sebagai
   **kontrol gagal-cepat**: bila versi PHP atau ekstensi menyimpang lagi di masa
   depan, build berhenti dengan pesan yang jelas.

Pelajaran yang diambil: image yang "terlihat benar" bisa tetap gagal karena syarat
platform di lockfile. Pemeriksaan ini seharusnya otomatis (Gate 2/Gate 3 pada
pipeline), bukan bergantung pada pembacaan manual — lihat §6.3.

### 6.2 Dump database adalah MySQL, bukan PostgreSQL

Dokumen arsitektur PO semula menyebut **PostgreSQL**, dan berkas dump diberi nama
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

### 6.3 Status MySQL: Resolved

PO telah menyelaraskan dokumen arsitektur: `1.1. Architecture.md` kini menetapkan
**MySQL 8.x / MariaDB 10.4+** dan menyebut eksplisit bahwa backend memakai
`DB_CONNECTION=mysql` pada port 3306. `2.1 Developer Analysis Result.md` bagian 6
juga memberi arahan langsung kepada Infra: kontainer database memakai `mysql:8.0`
atau `mariadb:10.4` pada jaringan privat `axon-network` tanpa ekspos port.

Temuan Infra (§6.2) dan keputusan PO kini **konsisten**, sehingga item handoff
lama sudah tertutup. Yang masih tertinggal adalah berkas milik Security Engineer —
`02-exposure-control.md` (matriks port) masih menyebut `postgres:16-alpine` dan
port `5432`, `01-tls-baseline.md` menyebut `sslmode`, dan `verify-deployment.sh`
menguji port `5432` alih-alih `3306`. Ini tetap dicatat sebagai handoff (§8.3).

## 7. Status Verifikasi

Sesuai kesepakatan, build/run tidak dieksekusi pada sesi penyusunan. Karena itu
laporan ini memisahkan apa yang **sudah dibuktikan** dari apa yang **menunggu
dijalankan**.

| # | Pemeriksaan | Cara | Status |
| :-: | :--- | :--- | :--- |
| 1 | Berkas Compose valid & variabel ter-interpolasi | `docker compose config -q` | ✅ terbukti |
| 2 | Hanya `proxy` yang punya published port | `docker compose config --format json` | ✅ terbukti |
| 3 | `internal: true` pada `axon-network` | idem | ✅ terbukti |
| 4 | `read_only: true` pada `app` & `proxy` | idem | ✅ terbukti |
| 5 | Berkas `initdb` least privilege ter-mount & berurutan setelah impor skema | idem | ✅ terbukti |
| 6 | Gate 4 (T-05, T-06, T-07, T-10, T-11) | `check-infra-policy.sh docs/INFRA/docker-compose.yml` | ✅ lolos |
| 7 | Pemeriksaan T-02 (raw query berinterpolasi) pada kode Developer | `check-infra-policy.sh` dijalankan dari root aplikasi | ✅ lolos |
| 8 | Sintaks seluruh skrip shell | `bash -n` dan `sh -n` pada 7 skrip | ✅ terbukti |
| 9 | Sertifikat development & SAN-nya | `openssl x509 -noout -subject -ext subjectAltName -dates` | ✅ terbukti |
| 10 | Workflow CI valid tanpa temuan | `actionlint .github/workflows/ci.yml` | ✅ lolos (exit 0) |
| 10b | Nama & lokasi berkas SBOM sesuai permintaan PO | pencocokan terhadap `README.md` butir backlog 2 | ✅ cocok |
| 11 | Seluruh action dipin ke commit SHA | pemeriksaan regex pada workflow | ✅ terbukti |
| 12 | Seluruh path yang dirujuk workflow benar-benar ada | skrip validasi | ✅ terbukti |
| 13 | Urutan `docker_setup_db` sebelum berkas initdb pada entrypoint MySQL | pembacaan sumber resmi `docker-library/mysql` | ✅ terverifikasi |
| 14 | Image dapat dibangun (PHP 8.4, `check-platform-reqs` lolos) | `docker compose build` | ⏳ menunggu dijalankan |
| 15 | Stack berjalan & semua service `healthy` | `docker compose up -d` + `docker compose ps` | ⏳ menunggu dijalankan |
| 16 | API mengembalikan data (`> 0`) | `curl -k https://localhost/api/dashboard/summary` | ⏳ menunggu dijalankan |
| 17 | Perilaku TLS, header, 405/404, isolasi port, non-root | `smoke-test.sh`, `verify-deployment.sh` | ⏳ menunggu dijalankan |
| 18 | User `dss_user` benar-benar hanya `SELECT` | `smoke-test.sh` (SHOW GRANTS) | ⏳ menunggu dijalankan |
| 19 | Pipeline hijau pada push pertama | tab Actions | ⏳ menunggu push |

Perintah lengkap beserta hasil yang diharapkan ada di
[panduan-build-run.md](./panduan-build-run.md) bagian 5, 6, dan 6.1–6.3.

Catatan kejujuran: seluruh baris bertanda ⏳ adalah **klaim yang belum dibuktikan**
dan tidak boleh dipresentasikan seolah sudah terverifikasi. Verifikasi statis memang
berguna (ia menangkap bug PHP 8.3 maupun masalah path pipeline), tetapi ia tidak dapat
menggantikan pembuktian runtime.

---

## 8. Analisis Risiko

### 8.1 Pre-Risk (teridentifikasi sebelum deployment)

| Kode | Risiko | Kontrol yang dipasang |
| :--- | :--- | :--- |
| PR-1 | Database terekspos ke host (T-05) | `axon-network` bersifat `internal: true` + tanpa `ports` pada `db` |
| PR-2 | Kredensial ter-hardcode (T-06) | Seluruh kredensial dari `${VAR}`; `.env` di-gitignore; `rm -f .env` saat build |
| PR-3 | Pesan error verbose ke client (T-07) | `APP_DEBUG=false`, `display_errors=Off`, `expose_php=Off` |
| PR-4 | Container berjalan sebagai root (T-10) | `USER` non-root pada kedua image; diverifikasi Gate 4 |
| PR-5 | Banjir request / resource exhaustion (T-08, T-09) | `limit_req`, batas CPU/RAM, `pm.max_children`, timeout FastCGI |
| PR-6 | Mixed content & CORS | Frontend satu origin dengan API; `VITE_API_URL=/api`; respons diperiksa agar tidak memuat wildcard origin |
| PR-7 | Sertifikat development dipakai di produksi | Diberi label tegas pada skrip dan README; jalur CA tepercaya didokumentasikan |
| PR-8 | Dampak SQLi diperlebar oleh hak tulis database | User aplikasi hanya `SELECT`, ditegakkan dan diverifikasi saat initdb (fail-closed) |
| PR-9 | Supply chain (T-11) — action/tool diganti versinya | Action di-pin ke commit SHA, tool di-pin versinya, Dependabot aktif |
| PR-10 | Versi PHP tidak memenuhi `composer.lock` | `ARG PHP_VERSION=8.4` + `composer check-platform-reqs` saat build (belajar dari bug §6.1) |

### 8.2 Residual Risk

| Kode | Risiko tersisa | Alasan masih ada | Mitigasi lanjutan |
| :--- | :--- | :--- | :--- |
| RR-1 | Sertifikat self-signed belum dipercaya browser | Kebutuhan pengujian Milestone; tidak ada domain publik | Terbitkan sertifikat CA (mis. Let's Encrypt) saat VPS/domain siap |
| RR-2 | **SAST belum menjadi gate nyata** (Gate 2 non-blocking) | Quality Gate mensyaratkan coverage ≥ 70% sedangkan tes masih 2 berkas skeleton; gate akan merah permanen bila dipaksa memblokir | Developer menambah tes API → hapus `continue-on-error` pada job `sast-sonar` |
| RR-3 | Kolom sensitif dapat muncul di respons API (EXP-7) | Berada di kode aplikasi, bukan ranah Infra | Handoff ke Developer |
| RR-4 | Query lambat belum dicatat (LOG-4) | Berada di kode aplikasi | Handoff ke Developer |
| RR-5 | Monitoring/alert belum ada | 03-logging-minimum 3.6 menugaskan Platform, tetapi belum dijadwalkan | Tambahkan alert 5xx/429/404 dan restart container berulang pada iterasi berikutnya |
| RR-6 | Backup & uji restore volume belum diuji | Belum termasuk lingkup Milestone 3 | Latihan backup/restore `db-data` (pola Bab 3) sebelum presentasi |
| RR-7 | Gate 1–5 belum pernah berjalan pada riwayat commit sebelumnya | Pipeline baru dipasang di akhir (lihat §5/§Tugas 4) | Jalankan gate pada kondisi saat ini, lalu aktifkan branch protection agar commit berikutnya wajib hijau |
| RR-8 | Sertifikat/temuan SONAR belum ada karena secret belum diisi | `gh` belum login dan `SONAR_TOKEN` belum dibuat | Isi secret + variable sesuai `panduan-build-run.md` §6.3 |
| RR-9 | Branch protection belum aktif | Perlu diatur manual di Settings repositori | Aktifkan required check `Security Gate - PASSED` untuk `dev` dan `main` |

### 8.3 Handoff ke Peran Lain

| Untuk | Item | Alasan |
| :--- | :--- | :--- |
| Security Engineer | `trivy.yaml` masih menulis `ignorefile: policy/.trivyignore` (relatif CWD) sehingga tidak ketemu bila dijalankan dari root repo. Untuk sekarang di-override di CI; lebih rapi bila nilainya diperbaiki di sumbernya | Temuan integrasi §Tugas 4 poin 2 |
| Security Engineer | Template `policy/pipeline/security-gate.yml` masih memakai `php-version: '8.3'` (akan gagal, lihat §6.1) dan path `policy/...` yang mengandaikan `policy/` ada di root repo. Versi yang benar-benar berjalan ada di `.github/workflows/ci.yml`; template sebaiknya diselaraskan atau ditandai sebagai usang | Mencegah orang menyalin template yang tidak jalan |
| Security Engineer | Baseline masih mengasumsikan PostgreSQL: `02-exposure-control.md` menyebut `postgres:16-alpine` & port `5432`, `01-tls-baseline.md` menyebut `sslmode`, dan `verify-deployment.sh` menguji port `5432` alih-alih `3306` | Engine MySQL sudah resmi disepakati PO (§6.3) |
| Security Engineer | Quality Gate `Axon-DSS-Baseline` mensyaratkan `new_coverage >= 70%`. Dengan nol tes API, syarat ini tidak dapat dipenuhi dan membuat gate tidak dapat dijadikan blocking | Perlu ditinjau: turunkan syarat, atau tunggu tes ada |
| Developer | Artefak SBOM (Tugas 3 Developer) — Infra sudah menyediakan `scripts/generate-sbom.sh` dan CI mengunggahnya sebagai artefak, tetapi kepemilikan/penyimpanan permanen ada di Developer | Prioritas P1 pada `2.1 Developer Analysis Result.md` |
| Developer | Penambahan **tes API** agar Gate 2 dapat dijadikan blocking (lihat RR-2) | Prasyarat agar SAST benar-benar menjadi gate |
| Developer | `TrustProxies` belum diatur (`bootstrap/app.php` masih kosong) | TLS-7 (`Laravel sadar proxy`). Dampak saat ini kecil karena Nginx mengirim skema HTTPS lewat FastCGI, tetapi tetap perlu ditetapkan bila topologi berubah |
| Developer | EXP-6 (whitelist parameter filter), EXP-7 (kolom sensitif), LOG-4 (query lambat) | Berada di kode aplikasi |
| Developer | `composer.json` menulis `"php": "^8.3"` padahal `composer.lock` mensyaratkan `>= 8.4.1`. Kontradiksi ini yang membuat version mismatch tidak terlihat dari manifest | Sebaiknya diselaraskan agar tidak menyesatkan pembaca berikutnya |
| Developer | README mengklaim tersedia `run-all.bat`, `run-backend.bat`, `run-frontend.bat`, tetapi **ketiganya tidak ada** di repositori. Selain itu `php.bat` masih menunjuk path absolut lokal mesin Developer (`D:\php84\php.exe`) sehingga tidak portabel | Dokumen yang menyebut berkas tidak ada akan menyesatkan saat presentasi; path absolut juga membuat skrip tidak jalan di mesin lain |
| PO | Perbarui scorecard setelah pekerjaan ini di-commit: *Automated CI/CD Pipeline* berubah dari 🟡 Parsial menjadi 🟢, dan *Software Bill of Materials* dari 🔴 Belum menjadi 🟢 (skrip tersedia, tinggal dijalankan) | Agar status pada README mencerminkan kondisi repositori |
| PO | Tegaskan lokasi resmi `sbom/` dan `reports/`: `1. Project-Overview.md` menaruhnya di **root**, sedangkan blok struktur README menaruh `sbom/` di bawah pohon aplikasi dan `reports/` di bawah `docs/SEC-ENG/` | Menghindari dua tafsir lokasi artefak (lihat §3.3 poin 5 dan 6) |
| PO | Kasus huruf pada struktur README: `docs/DEV/` vs kenyataan `docs/Dev/`. Hanya `docs/INFRA` yang sudah disamakan (sesuai keputusan), sedangkan `Dev` belum karena berada di ranah role lain | Mencegah kebingungan path di CI dan dokumentasi |
| PO | Konfirmasi bahwa hak `SELECT`-only untuk `dss_user` adalah perilaku yang diinginkan (migrasi Laravel tidak dapat dijalankan di kontainer) | Sudah diimplementasikan atas dasar `1.1. Architecture.md`, tetapi konsekuensinya perlu disepakati |

---

## 9. Rekomendasi untuk Environment Production-like

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
9. **Branch protection & review.** Pastikan perubahan `docs/INFRA/` juga melalui
   review dua orang dan pipeline hijau — konfigurasi proxy diperlakukan sebagai
   kode (Bab 4: tata kelola perubahan).
10. **Jadikan SAST gate yang memblokir.** Begitu tes API tersedia dan Quality Gate
    dapat dipenuhi, hapus `continue-on-error` pada job `sast-sonar`. SAST yang tidak
    pernah memblokir bukan gerbang, hanya laporan (Bab 1: gate terlalu longgar
    menciptakan kesan aman palsu).
11. **Repository ruleset di level organisasi.** Bila proyek berlanjut, aktifkan
    ruleset (bukan hanya branch protection) agar aturan berlaku seragam untuk semua
    branch, termasuk mencegah `git push --force` ke `main`.
12. **Perketat `mysql:8.0` → digest.** Image database saat ini memakai tag
    `mysql:8.0`. Untuk produksi, pin ke digest dan jadwalkan pembaruan terjadwal
    (Dependabot sudah mengusulkan pembaruannya).

---

## 10. Lampiran

### 10.1 Daftar artefak

| Berkas | Tugas |
| :--- | :---: |
| `docs/INFRA/docker-compose.yml` | 1 |
| `docs/INFRA/.env.example`, `docs/INFRA/.gitignore`, `docs/.dockerignore` | 1 |
| `docs/INFRA/docker/app/Dockerfile`, `php.ini`, `zz-axon-fpm.conf`, `entrypoint.sh` | 1, 2 |
| `docs/INFRA/docker/proxy/Dockerfile`, `nginx.conf` | 2, 3 |
| `docs/INFRA/docker/db/20-app-user-privileges.sh` | 3 |
| `docs/INFRA/scripts/gen-certs.sh`, `up.sh`, `smoke-test.sh` | 1, 2, 3 |
| `docs/INFRA/scripts/run-gates-local.sh`, `generate-sbom.sh` | 4 |
| `.github/workflows/ci.yml` | 4 |
| `.github/dependabot.yml` | 4 |
| `docs/INFRA/README.md`, `docs/INFRA/docs/panduan-build-run.md`, `docs/INFRA/docs/laporan-infra.md` | Dokumentasi |

### 10.2 Perintah pembuktian (dijalankan dari root repositori)

```bash
# 1. Validasi konfigurasi (tanpa menjalankan container)
docker compose -f docs/INFRA/docker-compose.yml config -q

# 2. Gate 4 milik Security Engineer
bash docs/SEC-ENG/policy/scripts/check-infra-policy.sh docs/INFRA/docker-compose.yml

# 3. Setelah stack dijalankan
bash docs/INFRA/scripts/smoke-test.sh

# 4. Evidence resmi dari Security Engineer
DEV_INSECURE=1 EVIDENCE_DIR=docs/INFRA/evidence \
  bash docs/SEC-ENG/policy/scripts/verify-deployment.sh https://localhost

# 5. Gate 1, 3, 4 secara lokal (tool sama dengan pipeline)
bash docs/INFRA/scripts/run-gates-local.sh

# 6. Gate 5 lokal: build image lalu pindai
WITH_IMAGE=1 bash docs/INFRA/scripts/run-gates-local.sh

# 7. SBOM CycloneDX (Prioritas P1 PO)
bash docs/INFRA/scripts/generate-sbom.sh

# 8. Validasi workflow CI
#    (actionlint; jalankan bila tersedia di mesinmu)
actionlint .github/workflows/ci.yml

# 9. Laporan audit mesin-terbaca (butir 3 backlog PO) ke folder Security Engineer
REPORTS_DIR=docs/SEC-ENG/reports bash docs/INFRA/scripts/run-gates-local.sh
```

### 10.3 Ringkasan keluaran Gate 4 yang sudah diperoleh

```text
[OK] T-05: service database tidak mem-publish port ke host
[OK] T-06: tidak ada password/APP_KEY literal di docs/INFRA/docker-compose.yml
[OK] T-07: APP_DEBUG tidak aktif di docs/INFRA/docker-compose.yml
[OK] T-10: ./docs/INFRA/docker/app/Dockerfile memakai USER www-data
[OK] T-10: ./docs/INFRA/docker/proxy/Dockerfile memakai USER nginx
[OK] T-06: .env tidak ter-track di Git
[OK] T-11: semua aset CDN memakai SRI (atau tidak ada aset CDN)
```

### 10.4 Ringkasan keluaran pemeriksaan tambahan

`actionlint` pada workflow (tanpa keluaran = tidak ada temuan):

```text
$ actionlint -color .github/workflows/ci.yml
$ echo $?
0
```

Validasi struktur workflow:

```text
workflow: name = security-gate
  jobs: ['secret-scan', 'sast-sonar', 'sca-sbom', 'infra-policy', 'image-scan', 'security-gate-passed']
  triggers: ['push', 'pull_request']
  needs OK
  semua action dipin ke SHA
  semua path rujukan ada
dependabot: version 2 | ecosystems: ['github-actions', 'docker', 'docker-compose']
```

Pemeriksaan bahwa hanya `proxy` yang punya published port:

```text
app    ports=- networks=['axon-network']
db     ports=- networks=['axon-network']
proxy  ports=[80->8080, 443->8443] networks=['axon-network', 'axon-public']
networks: {'axon-network': True, 'axon-public': False}
```
