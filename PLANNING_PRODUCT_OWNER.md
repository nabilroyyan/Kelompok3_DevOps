# 📋 DOKUMEN PERENCANAAN PROYEK (PROJECT PLANNING)
## SISTEM PENDUKUNG KEPUTUSAN (DECISION SUPPORT SYSTEM - DSS) PENJUALAN AXON
**Mata Kuliah:** Workshop DevSecOps — Evaluasi Tengah Semester (UTS)  
**Peran Penyusun:** Product Owner (PO)  
**Referensi Acuan:** [Role.md](file:///d:/Kuliah%20Informatika%20PENS/Semester%207/MPP-Workshop%20Devsecops/drive-download-20260916T030315Z-1-001/Role.md), [Deskripsi_Tugas.md](file:///d:/Kuliah%20Informatika%20PENS/Semester%207/MPP-Workshop%20Devsecops/drive-download-20260916T030315Z-1-001/Deskripsi_Tugas.md), & [bab-01.md](file:///d:/Kuliah%20Informatika%20PENS/Semester%207/MPP-Workshop%20Devsecops/drive-download-20260916T030315Z-1-001/bab-01.md)  
**Versi Dokumen:** 1.0 (Baseline Plan)  
**Status:** Disetujui untuk Eksekusi Tim (Ready for Threat Modeling & Sprint Execution)

---

## 1. Latar Belakang & Tujuan Proyek

### 1.1 Konteks Bisnis
Axon adalah perusahaan ritel internasional yang menjual model kendaraan klasik (*classic cars, motorcycles, planes, vintage cars*). Saat ini, manajemen Axon mengalami kendala dalam membaca tren penjualan, memantau perputaran stok barang di gudang, dan melacak pesanan tertunda (*orders on hold / in process*).

### 1.2 Tujuan Sistem (DSS Scope)
Tujuan proyek ini adalah membangun sebuah **Web Dashboard Decision Support System (DSS)** berbasis data relasional MySQL (`classicmodels`).
> **Instruksi Khusus Dosen:**  
> 1. **TIDAK MENGGUNAKAN POWER BI.** Solusi dibangun sebagai aplikasi web dashboard yang ter-kontainerisasi penuh (*containerized web application*) agar seluruh siklus *Software Supply Chain* dan *Security Gate* dapat diuji secara mandiri.
> 2. **FOKUS PADA DEVSECOPS:** Keberhasilan proyek tidak diukur dari kerumitan fitur transaksi e-commerce, melainkan pada penerapan rantai pasok perangkat lunak yang aman, kepatuhan arsitektur NIST SSDF & OWASP, serta penghasilan bukti audit (*Evidence as Product*) yang terverifikasi.

---

## 2. Batasan Aplikasi & Konsep Dashboard DSS (System Boundaries)

Untuk menjaga fokus tim dan meminimalkan area serangan (*attack surface*), Product Owner menetapkan batasan ketat sebagai berikut:

### 2.1 Batasan Fungsional (In-Scope vs Out-of-Scope)
* **IN-SCOPE (Dikerjakan):**
  * Dashboard bersifat **Read-Only / Analytical** (hanya menampilkan agregasi data dan visualisasi grafik).
  * Menampilkan 4 Modul Keputusan Utama:
    1. **Executive Revenue Overview:** Total Revenue, Total Volume Orders, Average Order Value (AOV), tren penjualan bulanan/tahunan.
    2. **Order Fulfillment & Logistics Health:** Status pengiriman (*Shipped, In Process, On Hold, Cancelled, Resolved, Disputed*).
    3. **Inventory & Stock Health:** Jumlah stok vs permintaan per kategori lini produk (*Classic Cars, Vintage Cars, Motorcycles*, dll.) untuk mendeteksi *dead-stock* atau risiko *stockout*.
    4. **Customer Intelligence & Demographics:** Daftar 10 pelanggan pembayar terbesar (*Top Spenders*), limit kredit, dan sebaran geografis pembeli (negara/kota).
  * Filter interaktif berbasis waktu (Tahun/Bulan) dan kategori lini produk.
  * Autentikasi sederhana berbasis peran (*Role-Based Dashboard Access*) untuk mengakses dasbor analitik internal.

* **OUT-OF-SCOPE (Dilarang Dikerjakan untuk Menghindari Bloat):**
  * ❌ **Tidak ada transaksi belanja pelanggan (Shopping Cart / Checkout / Payment Gateway).**
  * ❌ **Tidak ada fungsi Create, Update, Delete (CRUD) data penjualan secara terbuka dari antarmuka publik.**
  * ❌ **Tidak menggunakan Microsoft Power BI Desktop/Service.**

### 2.2 Arsitektur Aplikasi yang Direkomendasikan
* **Backend & API:** RESTful API ringan (misal: Python FastAPI / Flask / Node.js Express) yang membaca basis data MySQL `classicmodels`.
* **Frontend:** Web UI interaktif dan responsif (misal: React / HTML5 + Chart.js / Tailwind).
* **Database:** MySQL 8.0 (menggunakan skema resmi dari `Axon sales - Mysql Database.sql`).
* **Packaging:** Multi-container orchestration menggunakan **Docker & Docker Compose**.

---

## 3. Toleransi Risiko & Kebijakan Keamanan Bisnis (Risk Tolerance)

Mengacu pada prinsip tata kelola DevSecOps ([bab-01.md](file:///d:/Kuliah%20Informatika%20PENS/Semester%207/MPP-Workshop%20Devsecops/drive-download-20260916T030315Z-1-001/bab-01.md)), Product Owner menetapkan *Risk Appetite* dan aturan gerbang keamanan (*Security Gate*) sebagai hukum wajib:

| Kategori Risiko / Celah | Tingkat Toleransi | Kriteria Security Gate (CI/CD Rule) | Tindakan Bila Melanggar |
| :--- | :--- | :--- | :--- |
| **Kredensial & Secrets Bocor** | **ZERO TOLERANCE (0)** | Scan Gitleaks / TruffleHog pada *pre-commit* dan pipeline CI. | Build **GAGAL OTOMATIS**; commit ditolak. |
| **Kerentanan Kritis (CVE Critical)** | **ZERO TOLERANCE (0)** | Pemindaian dependensi (SCA) & Container Image Scan (Trivy). | Build dibatalkan; wajib remedi/patch < 24 jam. |
| **SQL Injection (SQLi)** | **ZERO TOLERANCE (0)** | SAST (SonarQube/Semgrep) & Wajib Parameterized Queries / ORM. | Pull Request ditolak saat review kode. |
| **Kerentanan Tinggi (CVE High)** | **Maksimal 1 (Dengan Syarat)** | Diizinkan hanya jika ada *Risk Waiver* tertulis & berbatas waktu dari PO. | Jika tanpa waiver, build gagal. |
| **Kerentanan Medium / Low** | **Toleransi Terkendali** | Dicatat ke backlog mitigasi teknis pasca-UTS. | Build lolos dengan peringatan (*warning*). |
| **Privilege Container (Root)** | **ZERO TOLERANCE (0)** | Container wajib berjalan dengan *Non-Root User* dan *read-only filesystem* jika memungkinkan. | Container ditolak saat validasi deployment. |

### 3.1 Prosedur Pengecualian Risiko (Risk Waiver Policy)
Jika dependensi tertentu memiliki kerentanan High yang belum tersedia patch resminya oleh vendor pihak ketiga, tim dapat mengajukan **Security Waiver Form** kepada Product Owner dengan melampirkan:
1. Alasan bisnis mengapa komponen tersebut esensial.
2. Kontrol kompensasi (misal: port tidak dibuka ke publik atau validasi input ketat).
3. Batas waktu kedaluwarsa pengecualian (maksimal 14 hari).

---

## 4. Instruksi Kerja & Pembagian Tugas Tim (Task Assignment)

Sesuai mandat [Role.md](file:///d:/Kuliah%20Informatika%20PENS/Semester%207/MPP-Workshop%20Devsecops/drive-download-20260916T030315Z-1-001/Role.md) dan simulasi 4 peran untuk 3 anggota kelompok:

```
                  ┌─────────────────────────────────────┐
                  │       PRODUCT OWNER (PO)            │
                  │  - Risk Tolerance & Governance      │
                  │  - DSS Dashboard Scope & Boundary   │
                  │  - Task Assignment & Business Plan  │
                  └──────────────────┬──────────────────┘
                                     │
           ┌─────────────────────────┼─────────────────────────┐
           ▼                         ▼                         ▼
┌──────────────────────┐  ┌──────────────────────┐  ┌──────────────────────┐
│  SECURITY ENGINEER   │  │      DEVELOPER       │  │ INFRASTRUCTURE ENG.  │
│ - Threat Modeling    │  │ - Secure Coding      │  │ - Docker Environment │
│   (v1 & v2)          │  │ - No SQLi / Param Q  │  │ - Policy Admission   │
│ - Security Policy    │  │ - Generate SBOM      │  │ - Hardened Pipeline  │
│ - Scan & Gate Rules  │  │ - Remediate Findings │  │ - Registry & Deploy  │
└──────────────────────┘  └──────────────────────┘  └──────────────────────┘
```

### 4.1 Tugas untuk Security Engineer
* **Tugas 1 (Prioritas Utama):** Menyusun dokumen **Threat Modeling Versi 1 (v1)** berdasarkan konsep DSS di atas. Gunakan framework STRIDE / PASTA untuk mengidentifikasi ancaman kebocoran data (*data breach*), manipulasi agregasi analitik, dan eksfiltrasi basis data.
* **Tugas 2:** Menyusun aturan kebijakan (*policy as code*) untuk security gate (misal: aturan Trivy, SonarQube, atau linter keamanan).
* **Tugas 3:** Melakukan audit hasil pemindaian keamanan (SAST, SCA, Secret Scanning, Container Scanning) dan mendokumentasikan laporan ke folder `/reports`.
* **Tugas 4:** Memperbarui **Threat Modeling ke Versi 2 (v2)** saat terjadi perubahan rancangan atau setelah mitigasi diimplementasikan oleh Developer.

### 4.2 Tugas untuk Developer
* **Tugas 1:** Mengembangkan antarmuka Dashboard DSS berbasis web sesuai 4 modul keputusan bisnis di atas, dengan menghubungkan backend ke database MySQL `classicmodels`.
* **Tugas 2 (Secure Coding Practice):** Wajib menggunakan *parameterized queries* atau *prepared statements* untuk semua kueri analitik (mengadopsi logika kueri dari `Axon SQL.sql`). Dilarang keras melakukan konkatenasi string SQL mentah!
* **Tugas 3:** Menghasilkan dokumen **Software Bill of Materials (SBOM)** dalam format standar industri (CycloneDX JSON atau SPDX) untuk seluruh dependensi frontend dan backend. Simpan di folder `/sbom`.
* **Tugas 4:** Memperbaiki temuan kerentanan (*vulnerability remediation*) yang dilaporkan oleh Security Engineer dari hasil pemindaian SAST/SCA.

### 4.3 Tugas untuk Infrastructure / Platform Engineer
* **Tugas 1:** Menyiapkan lingkungan *deployment* berbasis **Docker & Docker Compose** untuk menjalankan container Database MySQL dan container Web Dashboard DSS.
* **Tugas 2 (Hardening Container):** Mengonfigurasi `Dockerfile` dengan prinsip *least privilege* (menjalankan aplikasi dengan user non-root, menggunakan base image minimal/alpine, dan membatasi ekspos port).
* **Tugas 3 (Policy Admission & Network):** Mengatur konfigurasi jaringan internal container (hanya backend yang dapat menghubungi database MySQL; database tidak boleh diekspos langsung ke jaringan publik).
* **Tugas 4:** Menyiapkan otomasi build/pipeline (misalnya via GitHub Actions atau runner lokal) dan memastikan tidak memodifikasi kode aplikasi yang dibuat oleh Developer.

---

## 5. Tata Kelola Repositori & Struktur Direktori Standar DevSecOps

Mengacu pada panduan praktikum Bab 1 ([bab-01.md](file:///d:/Kuliah%20Informatika%20PENS/Semester%207/MPP-Workshop%20Devsecops/drive-download-20260916T030315Z-1-001/bab-01.md)), repositori Git proyek wajib memiliki struktur direktori terstandarisasi sebagai bukti audit:

```text
axon-devsecops-dss/
├── .github/workflows/          # Pipeline CI/CD & Automated Security Gates
├── app/                        # Source code aplikasi Dashboard DSS
│   ├── backend/                # API service & kueri database (Secure Coding)
│   └── frontend/               # UI dashboard analitik interaktif
├── database/                   # Skrip inisialisasi basis data (classicmodels.sql)
├── policy/                     # Kebijakan keamanan, gate rules, & Trivy/OPA configs
├── reports/                    # Bukti audit hasil scan (SARIF, SAST, SCA, Container)
├── sbom/                       # Artefak Software Bill of Materials (CycloneDX JSON/SPDX)
├── keys/                       # Kunci verifikasi/tanda tangan (PUBLIC keys only! DILARANG private keys)
├── docs/                       # Dokumentasi resmi proyek
│   ├── PLANNING_PRODUCT_OWNER.md  # Dokumen rencana PO (dokumen ini)
│   ├── THREAT_MODELING_V1.md      # Dokumen threat model versi 1
│   ├── THREAT_MODELING_V2.md      # Dokumen threat model versi 2 (pasca mitigasi)
│   └── WAIVER_LOG.md              # Catatan pengecualian risiko yang disetujui PO
├── docker-compose.yml          # Konfigurasi orkestrasi runtime
└── README.md                   # Panduan instalasi, arsitektur, dan ringkasan tim
```

---

## 6. Jadwal & Milestone Kerja Menuju Presentasi UTS

| Tahap / Sprint | Durasi | Target Deliverables Utama | Penanggung Jawab |
| :--- | :--- | :--- | :--- |
| **Milestone 1: Planning & Threat Modeling v1** | Hari 1 - 3 | - Dokumen `PLANNING_PRODUCT_OWNER.md`<br>- Dokumen `THREAT_MODELING_V1.md`<br>- Inisialisasi repo & branch protection | Product Owner & Security Engineer |
| **Milestone 2: Secure Development & SBOM** | Hari 4 - 8 | - Source code Dashboard DSS di folder `/app`<br>- Implementasi Parameterized SQL<br>- Generasi artefak SBOM di `/sbom` | Developer |
| **Milestone 3: Containerization & Security Scanning** | Hari 9 - 11 | - Dockerfile non-root & Docker Compose<br>- Hasil scan SAST/SCA/Container di `/reports`<br>- Triage celah keamanan & mitigasi kode | Infra Eng & Security Eng |
| **Milestone 4: Threat Model v2, Laporan & Presentasi** | Hari 12 - 14 | - Dokumen `THREAT_MODELING_V2.md`<br>- Laporan PDF untuk Etol<br>- Simulasi presentasi 15 menit | Seluruh Anggota Tim |

---

## 7. Kriteria Selesai (Definition of Done - DoD) untuk UTS

Suatu deliverable dinyatakan **SELESAI (DONE)** dan siap dipresentasikan di depan dosen jika memenuhi kriteria:
1. ✅ **Tidak ada Power BI:** Dashboard berjalan mandiri di web browser via container Docker.
2. ✅ **Rekam Jejak Git Valid:** Setiap anggota melakukan *commit* sesuai dengan perannya masing-masing (dosen dapat melihat keaktifan tiap role di commit history).
3. ✅ **Security Gate Terbukti:** Terdapat bukti laporan scan (SAST, SCA, Secret Scanning, Container Image) di folder `/reports`.
4. ✅ **Zero Critical:** Tidak ada celah *Critical* yang belum dimitigasi.
5. ✅ **Artefak Lengkap:** Repositori memuat file perencanaan (PO), Threat Modeling v1 & v2 (Security), Source Code & SBOM (Dev), serta Dockerfile & Config (Infra).
6. ✅ **Akses Dosen Terbuka:** Dosen telah diundang sebagai kolaborator di repositori GitHub dan Docker Registry terkait.
