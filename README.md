# Kelompok 3 — DevOps

Selamat datang di repositori **Kelompok 3** untuk mata kuliah/topik **DevOps**.
Repositori ini digunakan sebagai wadah kolaborasi seluruh anggota kelompok dalam mengerjakan tugas, proyek, dan praktikum.

---

## 👥 Anggota Kelompok

| No | Nama | NIM | Peran |
| :-: | :--- | :--- | :--- |
| 1 | Muhammad Nabil Royyan | 3126640032 | **Product Owner** |
| 2 | Anifa Aulia Abdari | 3126640053 | **Developer** |
| 3 | Adam Rasyid Nurmuhammad | 3126640025 | **Security Engineer** |
| 4 | Ale Perdana Putra Darmawan | 3126640016 | **Infrastructure Engineer** |

---

## 🧩 Pembagian Peran & Tanggung Jawab

### 1. Product Owner — Muhammad Nabil Royyan (3126640032)
- Menentukan visi, tujuan, dan prioritas proyek.
- Mengelola serta menyusun *product backlog*.
- Menjembatani kebutuhan pengguna dengan tim teknis.
- Memastikan hasil pekerjaan sesuai kebutuhan dan diterima (*acceptance*).

### 2. Developer — Anifa Aulia Abdari (3126640053)
- Menulis dan memelihara kode aplikasi.
- Melakukan *code review* serta mengikuti standar gaya penulisan kode.
- Menjaga kualitas melalui pengujian dan perbaikan bug.
- Berkolaborasi dalam pengembangan fitur secara iteratif.

### 3. Security Engineer — Adam Rasyid Nurmuhammad (3126640025)
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
git
## 📁 Struktur Repositori (Rencana)

```
To be announced
```

---

## 🔄 Alur Kerja Kolaborasi (Git Flow)

1. Buat branch baru dari `main` sesuai penamaan:
   - `feature/nama-fitur`
   - `fix/nama-perbaikan`
   - `docs/nama-dokumentasi`
2. Lakukan commit dengan pesan yang jelas, contoh: `feat: tambah endpoint login`.
3. Push branch dan ajukan **Pull Request (PR)** ke `main`.
4. Minimal satu anggota melakukan *review* sebelum PR di-*merge*.
5. Pastikan pipeline CI berjalan hijau sebelum merge.

---

## 📌 Aturan Kontribusi

- Gunakan **Conventional Commits** (`feat:`, `fix:`, `docs:`, `chore:`, dll.).
- Jangan mengirim kredensial/rahasia ke repositori.
- Sertakan dokumentasi untuk setiap perubahan besar.
- Komunikasikan progres dan kendala secara berkala.

---

## 📄 Lisensi

Proyek ini dilisensikan sesuai berkas [LICENSE](LICENSE).

---


## Panduan Setup Database & Koneksi Laravel

1. **Import Database**
   - Buat database MySQL baru dengan nama `classicmodels`.
   - masuk ke folder axon-dss `cd axon-dss`.
   - jalankan perintah `mysql -u root -p classicmodels < "Axon sales - Mysql Database.sql"`' untuk import ke database(pastikan file Axon sales - Mysql Database.sql ada di dalam file laravel axon-dss).

2. **Konfigurasi Environment**
   - Duplikasi file `.env.example` menjadi `.env` (jika cloning dari repo):
     jalan perintah ` cp .env.example .env`
   - Jalankan `php artisan key:generate`.
   - Sesuaikan konfigurasi database pada file `.env`:
     ```env
     DB_CONNECTION=mysql
     DB_HOST=127.0.0.1
     DB_PORT=3306
     DB_DATABASE=classicmodels
     DB_USERNAME=root
     DB_PASSWORD=

     SESSION_DRIVER=file
     ```


3. **Verifikasi Koneksi**
   - Jalankan perintah `php artisan config:clear` untuk memperbarui konfigurasi.



<div align="center">

**Kelompok 3 — DevOps**

</div>
