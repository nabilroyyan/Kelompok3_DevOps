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
