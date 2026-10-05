# Kelompok 3 — DevOps

Selamat datang di repositori **Kelompok 3** untuk mata kuliah/topik **DevOps**.
Repositori ini digunakan sebagai wadah kolaborasi seluruh anggota kelompok dalam mengerjakan tugas, proyek, dan praktikum.

---

## 👥 Anggota Kelompok

| No | Nama | NIM | Peran |
| :-: | :--- | :--- | :--- |
| 1 | Adam Rasyid Nurmuhammad | 3126640025 | **Product Owner** |
| 2 | Muhammad Nabil Royyan | 3126640032 | **Developer** |
| 3 | Anifa Aulia Abdari | 3126640053 | **Security Engineer** |
| 4 | Ale Perdana Putra Darmawan | 3126640016 | **Infrastructure Engineer** |

---

## 🧩 Pembagian Peran & Tanggung Jawab

### 1. Product Owner — Adam Rasyid Nurmuhammad (3126640025)
- Menentukan visi, tujuan, dan prioritas proyek.
- Mengelola serta menyusun *product backlog*.
- Menjembatani kebutuhan pengguna dengan tim teknis.
- Memastikan hasil pekerjaan sesuai kebutuhan dan diterima (*acceptance*).

### 2. Developer — Muhammad Nabil Royyan (3126640032)
- Menulis dan memelihara kode aplikasi.
- Melakukan *code review* serta mengikuti standar gaya penulisan kode.
- Menjaga kualitas melalui pengujian dan perbaikan bug.
- Berkolaborasi dalam pengembangan fitur secara iteratif.

### 3. Security Engineer — Anifa Aulia Abdari (3126640053)
- Menerapkan praktik *secure coding* dan manajemen rahasia (*secrets*).
- Mengelola keamanan pipeline CI/CD serta hak akses.
- Melakukan pemeriksaan kerentanan dependensi dan konfigurasi.
- Menyusun kebijakan keamanan dan mitigasi risiko.

### 4. Infrastructure Engineer — Ale Perdana Putra Darmawan (3126640016)
- Menyiapkan dan memelihara infrastruktur serta lingkungan deployment.
- Membangun dan mengelola pipeline CI/CD.
- Melakukan otomatisasi konfigurasi dan *monitoring*.
- Menjaga ketersediaan, skalabilitas, dan keandalan sistem.

---

## 🛠️ Rencana Teknologi

| Kategori | Alat/Teknologi |
| :--- | :--- |
| Version Control | Git, GitHub |
| CI/CD | GitHub Actions |
| Containerization | Docker, Docker Compose |
| Cloud/Server | VPS / Cloud Provider |

---
## 📁 Struktur Repositori (Rencana)

Repositori ini menerapkan tata kelola berbasis peran (*Role-Based Workspace*) untuk mendukung kolaborasi tim DevSecOps serta integrasi pipeline otomatis:

```text
Kelompok3_DevOps/
├── .github/
│   └── workflows/              
├── docs/                       
│   ├── PO/                     
│   │   ├── 1. Project-Overview.md            
│   │   ├── 1.1. Architecture.md              
│   │   ├── 1.2 Risk.md                       
│   │   ├── 1.3. Task-Role.md                 
│   │   ├── 1.4. Milestone.md                 
│   │   └── 2.1 Developer Analysis Result.md  
│   ├── DEV/                    
│   │   └── axon-devsecops-dss/
│   │       ├── app/
│   │       │   ├── backend/    
│   │       │   └── frontend/   
│   │       ├── database/       
│   │       ├── sbom/           
│   ├── SEC-ENG/                
│   │   ├── Threat-Modelling-V1.md           
│   │   ├── policy/             
│   │   └── reports/            
│   └── INFRA/                  
│       ├── docker/             
│       ├── docker-compose.yml  
│       ├── certs/             
│       ├── scripts/           
│       └── README.md           
├── references/                
├── LICENSE                     
└── README.md                   
```




## 🛡️ Status Implementasi DevSecOps

Evaluasi kesiapan sistem terhadap integrasi praktik **DevSecOps**, keamanan kode, dan arsitektur kontainer berdasarkan tanggung jawab 4 peran:

### 1. Ringkasan Status Proyek (Scorecard)
- **Fase Saat Ini:** Transisi dari **Milestone 2 (Secure Development)** menuju **Milestone 3 (Containerization & Security Scanning)**.
- **Tingkat Kesiapan (Readiness):** **~75%** (Aplikasi, kebijakan keamanan, dan konfigurasi Docker sudah siap; integrasi pipeline otomatis dan pengujian live scan sedang berjalan).

| Domain DevSecOps | Status | Keterangan |
| :--- | :---: | :--- |
| **Secure Coding & Anti-SQLi** | 🟢 **Selesai** | Parameterized query (Laravel Query Builder), 100% read-only API. |
| **Secrets Management** | 🟢 **Selesai** | `.env` terisolasi dari Git, konfigurasi `gitleaks.toml` tersedia. |
| **Threat Modeling (v1)** | 🟢 **Selesai** | Analisis STRIDE & PASTA terdokumentasi di `docs/SEC-ENG/Threat-Modelling-V1.md`. |
| **Security Policy as Code** | 🟢 **Selesai** | Aturan Trivy, Gitleaks, dan SonarQube Quality Gate siap pakai. |
| **Container Hardening Specs** | 🟢 **Selesai** | Dockerfile PHP-FPM & Nginx proxy (non-root) dan `docker-compose.yml` siap di `docs/INFRA`. |
| **Software Bill of Materials (SBOM)**| 🔴 **Belum** | Artefak CycloneDX / SPDX di folder `/sbom` belum di-generate. |
| **Automated CI/CD Pipeline** | 🟡 **Parsial** | Aturan `security-gate.yml` sudah dibuat, tetapi belum dipasang ke `.github/workflows/`. |
| **Audit Scan Reports (`/reports`)** | 🟡 **Parsial** | Folder `/reports` belum berisi output bukti scan aktual (SARIF / JSON). |

---

### 2. Apa yang SUDAH Diimplementasikan (Accomplished)

#### A. Product Owner (PO)
- [x] Menyusun dokumen visi, tata kelola, dan batasan ketat DSS di [1. Project-Overview.md](docs/PO/1.%20Project-Overview.md).
- [x] Menyusun matriks toleransi risiko dan kriteria *Security Gate* di [1.2 Risk.md](docs/PO/1.2%20Risk.md).
- [x] Menyusun pembagian tugas dan rincian peran tim di [1.3. Task-Role.md](docs/PO/1.3.%20Task-Role.md).
- [x] Menyusun target jadwal sprint kerja di [1.4. Milestone.md](docs/PO/1.4.%20Milestone.md).
- [x] Melakukan validasi dan audit hasil implementasi teknis developer di [2.1 Developer Analysis Result.md](docs/PO/2.1%20Developer%20Analysis%20Result.md).
- [x] Menyelaraskan spesifikasi arsitektur 3-tier berbasis database MySQL di [1.1. Architecture.md](docs/PO/1.1.%20Architecture.md).

#### B. Developer (DEV)
- [x] Mengembangkan antarmuka Dashboard DSS berbasis **React 19 + Vite 8** dengan visualisasi grafik interaktif (Recharts & Chart.js).
- [x] Membangun **RESTful API Laravel 13 + PHP 8.4** dengan 12 endpoint analitik.
- [x] Menghubungkan sistem ke basis data relasional **MySQL `classicmodels`** (8 tabel).
- [x] **Penerapan Secure Coding (Zero SQLi):** Seluruh kueri menggunakan Fluent Query Builder dengan *Prepared Statements* (PDO Parameter Binding).
- [x] **Pengurangan Bidang Serangan (Attack Surface Reduction):** Seluruh route API hanya melayani metode `GET` (*read-only*), tanpa transaksi atau CRUD terbuka.
- [x] **Audit Dependensi Bersih:** Dependensi frontend (`npm audit`) mencatatkan **0 vulnerabilities**.
- [x] Menyediakan skrip launcher pengujian lokal (`run-all.bat`, `run-backend.bat`, `run-frontend.bat`).

#### C. Security Engineer (SEC-ENG)
- [x] Menyusun dokumen **Threat Modeling v1** ([docs/SEC-ENG/Threat-Modelling-V1.md](docs/SEC-ENG/Threat-Modelling-V1.md)) menggunakan framework STRIDE dan PASTA.
- [x] Menetapkan aturan pemindaian kebocoran rahasia (*Secret Scanning*) via `policy/gitleaks.toml`.
- [x] Menetapkan aturan pemindaian kerentanan kontainer & dependensi via `policy/trivy.yaml` dan `.trivyignore`.
- [x] Menetapkan aturan kualitas kode (*SAST*) via `policy/sonarqube/sonar-project.properties` dan `setup-quality-gate.sh`.
- [x] Menyusun spesifikasi kebijakan baseline: TLS baseline, kontrol eksposur, audit logging minimum, dan register risiko.
- [x] Merancang skrip pengujian kepatuhan infrastruktur (`policy/scripts/check-infra-policy.sh`).

#### D. Infrastructure Engineer (INFRA)
- [x] Menyusun orkestrasi multi-kontainer melalui [docs/INFRA/docker-compose.yml](docs/INFRA/docker-compose.yml).
- [x] Mengonfigurasi `Dockerfile` backend PHP-FPM dengan prinsip *least privilege* (user non-root `www-data`, ekstensi PDO terisolasi).
- [x] Mengonfigurasi `Dockerfile` reverse proxy Nginx beserta template pengerasan konfigurasi (`nginx.conf`).
- [x] Menyusun skrip otomatisasi sertifikat TLS mandiri (`scripts/gen-certs.sh`) dan pengujian kesehatan (`scripts/smoke-test.sh`).
- [x] Menyusun dokumentasi infrastruktur dan panduan kontainer di `docs/INFRA/README.md`.

---

### 3. Apa yang BELUM Diimplementasikan (Backlog / Action Items)

Berikut adalah daftar pekerjaan yang perlu diselesaikan menuju **Milestone 3** dan **Milestone 4 (Final UTS)**:

1. **Aktivasi Pipeline CI/CD di `.github/workflows/` (Prioritas Utama):**
   - File template `docs/SEC-ENG/policy/pipeline/security-gate.yml` perlu diintegrasikan ke `.github/workflows/ci.yml` pada root repositori agar pemindaian (Gitleaks, Trivy, Linter, Test) berjalan otomatis pada setiap commit/PR.
2. **Generasi Dokumen SBOM (`/sbom`):**
   - Developer perlu meng-generate dokumen SBOM berstandar CycloneDX JSON (`backend-sbom.cdx.json` dan `frontend-sbom.cdx.json`) dan meletakkannya di folder `/sbom`.
3. **Penyimpanan Artefak Hasil Audit Pemindaian (`/reports`):**
   - Menjalankan pemindaian nyata (Gitleaks, Trivy, Semgrep/SonarQube) dan mendokumentasikan log/laporan resmi (format SARIF/JSON/PDF) ke folder `docs/SEC-ENG/reports/`.
4. **Uji Coba Integrasi Kontainer Runtime (Docker Run & Test):**
   - Menjalankan dan memvalidasi `docker-compose.yml` di environment lokal/VPS untuk memastikan kontainer frontend, backend, dan database MySQL terhubung lancar di jaringan privat `axon-network`.
5. **Penyempurnaan Modul Bisnis DSS:**
   - Menambahkan endpoint visualisasi agregasi status pesanan pengiriman (*Order Fulfillment*) dan rasio stok vs permintaan barang (*Inventory Health*).
6. **Threat Modeling Versi 2 (v2):**
   - Menyusun dokumen `Threat-Modelling-V2.md` yang mencatat evaluasi risiko pasca-mitigasi dan kesiapan deployment final.

---
## 🚀 Panduan Menjalankan Projek (Axon DSS)

Ikuti langkah-langkah berikut secara berurutan untuk menjalankan database, backend, dan frontend di lingkungan lokal:

### 1. Prasyarat Sistem
Pastikan perangkat Anda telah terpasang:
- **MySQL Server** (XAMPP / Standalone) aktif pada port `3306`.
- **PHP 8.4 atau lebih baru** (dengan ekstensi `pdo_mysql`, `curl`, `mbstring`, `openssl`).
- **Composer** (v2.x).
- **Node.js** (v20+ / v22+) dan **npm**.

---

### 2. Langkah 1: Menyiapkan & Menjalankan Database (MySQL)

1. Pastikan layanan MySQL sedang berjalan (misalnya melalui XAMPP Control Panel klik **Start** pada modul MySQL).
2. Buka terminal, masuk ke direktori repository, lalu impor skema database `classicmodels`:
   ```bash
   cd "docs/DEV/axon-devsecops-dss"
   mysql -u root -p < database/axon-postgresql.sql
   ```
   *(Tekan Enter jika akun root lokal Anda tidak menggunakan password).*
3. Verifikasi bahwa database dan tabel berhasil dibuat:
   ```bash
   mysql -u root -p -e "SHOW TABLES FROM classicmodels;"
   ```

---

### 3. Langkah 2: Menjalankan Backend (Laravel API)

1. Buka **Terminal 1**, lalu masuk ke direktori backend:
   ```bash
   cd "docs/DEV/axon-devsecops-dss/app/backend"
   ```
2. Pasang dependensi PHP (jika baru pertama kali):
   ```bash
   composer install
   ```
3. Siapkan file `.env`:
   - Salin file template: `cp .env.example .env` (atau `copy .env.example .env` di Windows).
   - Pastikan konfigurasi database pada `.env` sudah sesuai:
     ```dotenv
     APP_URL=http://127.0.0.1:8000
     DB_CONNECTION=mysql
     DB_HOST=127.0.0.1
     DB_PORT=3306
     DB_DATABASE=classicmodels
     DB_USERNAME=root
     DB_PASSWORD=
     ```
4. Buat kunci aplikasi dan jalankan migrasi Laravel:
   ```bash
   php artisan key:generate
   php artisan optimize:clear
   php artisan migrate
   ```
5. Jalankan backend server:
   ```bash
   php artisan serve --host=127.0.0.1 --port=8000
   ```
   > **Catatan:** Backend akan aktif di `http://127.0.0.1:8000`. Biarkan terminal ini tetap terbuka.
6. Uji koneksi API di terminal lain:
   ```bash
   curl http://127.0.0.1:8000/api/dashboard/summary
   ```

---

### 4. Langkah 3: Menjalankan Frontend (React + Vite)

1. Buka **Terminal 2**, lalu masuk ke direktori frontend:
   ```bash
   cd "docs/DEV/axon-devsecops-dss/app/frontend"
   ```
2. Pasang dependensi JavaScript (jika baru pertama kali):
   ```bash
   npm install
   ```
3. Pastikan konfigurasi alamat API pada `.env.local` sudah mengarah ke backend:
   ```dotenv
   VITE_API_URL=http://127.0.0.1:8000/api
   ```
4. Jalankan server pengembangan Vite:
   ```bash
   npm run dev -- --host 127.0.0.1
   ```
   > **Catatan:** Frontend akan aktif di `http://127.0.0.1:5173`. Biarkan terminal ini tetap terbuka.

---

### 5. Mengakses Dashboard

Buka peramban web (browser) Anda dan akses alamat:
👉 **[http://127.0.0.1:5173](http://127.0.0.1:5173)**

Aplikasi secara otomatis mengarahkan ke halaman `/overview` dan menampilkan agregasi data analitik secara interaktif dari database MySQL.

---


## 📄 Lisensi

Proyek ini dilisensikan sesuai berkas [LICENSE](LICENSE).

---

<div align="center">

**Kelompok 3 — DevOps &copy; 2026**

</div>
