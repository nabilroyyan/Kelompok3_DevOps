# Panduan Instalasi dan Menjalankan Axon DSS

>Panduan ini digunakan setiap anggota tim untuk menyiapkan dan menjalankan Axon DSS di komputer lokal. Backend menggunakan Laravel, frontend menggunakan React + Vite, dan data analitik memakai database MySQL `classicmodels`.

## 1. Prasyarat

Pasang perangkat berikut sebelum memulai:

- Git
- PHP 8.3 atau lebih baru, dengan ekstensi `pdo_mysql`
- Composer
- Node.js 20.19+ atau 22.12+ beserta npm
- MySQL Server dan MySQL CLI

Unduh installer dari situs resminya: [Git](https://git-scm.com/downloads), [PHP](https://www.php.net/downloads), [Composer](https://getcomposer.org/download/), [Node.js](https://nodejs.org/en/download), dan [MySQL](https://dev.mysql.com/downloads/mysql/).

Untuk macOS dengan Homebrew, perangkat utama dapat dipasang dengan:

```sh
brew install php composer node mysql
brew services start mysql
```

Pastikan command tersedia dan versi PHP sesuai:

```sh
git --version
php -v
composer -V
node -v
npm -v
mysql --version
php -m | grep -i pdo_mysql
```

Jika `pdo_mysql` tidak muncul, aktifkan/install ekstensi tersebut pada instalasi PHP sebelum melanjutkan.

## 2. Ambil Source Code

Clone URL repository tim, lalu masuk ke direktori project:

```sh
git clone <URL-repository-tim>
cd axon-devsecops-dss
```

Semua path dan command berikut dijalankan dari direktori root `axon-devsecops-dss`, kecuali disebutkan lain.

## 3. Siapkan Database MySQL

Pastikan MySQL Server sedang aktif. File yang digunakan adalah [database/axon-postgresql.sql](database/axon-postgresql.sql). Walaupun nama file memuat kata `postgresql`, isinya menggunakan sintaks **MySQL** dan membuat database `classicmodels` secara otomatis.

Impor database:

```sh
mysql -u root -p < database/axon-postgresql.sql
```

Masukkan password MySQL saat diminta. Pada instalasi lokal tanpa password, tekan Enter ketika diminta.

> **Peringatan:** script ini menjatuhkan lalu membuat ulang tabel-tabel Classic Models di database `classicmodels`. Jalankan hanya pada database lokal/baru atau backup data terlebih dahulu. Jangan jalankan pada database yang berisi data penting. Jangan gunakan `app/backend/fixed-postgres.sql` untuk langkah ini.

Pastikan database berhasil dibuat:

```sh
mysql -u root -p -e "SHOW TABLES FROM classicmodels;"
```

Tabel yang dipakai dashboard antara lain `customers`, `products`, `orders`, `orderdetails`, dan `employees`.

## 4. Instalasi dan Konfigurasi Backend

Buka terminal pertama dari root project:

```sh
cd app/backend
composer install
cp .env.example .env
```

Jika file `.env` sudah ada, jangan jalankan `cp` lagi karena konfigurasi lokal dapat tertimpa. Buka `app/backend/.env`, lalu sesuaikan nilai berikut dengan MySQL lokal:

```dotenv
APP_URL=http://127.0.0.1:8000
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=classicmodels
DB_USERNAME=root
DB_PASSWORD=password_mysql_anda
```

Ganti `DB_USERNAME` dan `DB_PASSWORD` sesuai akun MySQL masing-masing. Jika akun `root` tidak memakai password, biarkan `DB_PASSWORD=` kosong.

Buat application key, bersihkan cache konfigurasi, lalu jalankan migration Laravel:

```sh
php artisan key:generate
php artisan optimize:clear
php artisan migrate
```

Migration membuat tabel pendukung Laravel seperti cache, jobs, dan personal access tokens di database `classicmodels`; migration ini tidak menggantikan data Classic Models yang diimpor sebelumnya.

Jalankan backend dan biarkan terminal ini tetap terbuka:

```sh
php artisan serve --host=127.0.0.1 --port=8000
```

Backend tersedia di `http://127.0.0.1:8000`. Di terminal lain, endpoint ringkasan dapat diuji dengan:

```sh
curl http://127.0.0.1:8000/api/dashboard/summary
```

Respons yang berhasil berupa JSON, misalnya berisi `total_customers`, `total_products`, dan `total_orders`.

## 5. Instalasi dan Menjalankan Frontend

Buka terminal kedua dari root project:

```sh
cd app/frontend
npm install
```

Frontend menggunakan `http://localhost:8000/api` sebagai alamat API bawaan. Jika alamat backend berbeda, buat file `app/frontend/.env.local`:

```dotenv
VITE_API_URL=http://127.0.0.1:8000/api
```

Jalankan Vite dan biarkan terminal tetap terbuka:

```sh
npm run dev -- --host 127.0.0.1
```

Buka URL yang dicetak Vite, biasanya [http://127.0.0.1:5173](http://127.0.0.1:5173). Dashboard akan mengarahkan halaman awal ke `/overview` dan mengambil data dari backend.

## 6. Menjalankan Kembali Project

Setiap kali mulai bekerja, pastikan MySQL aktif, lalu jalankan dua server pada terminal terpisah dari root repository:

```sh
cd app/backend
php artisan serve --host=127.0.0.1 --port=8000
```

```sh
cd app/frontend
npm run dev -- --host 127.0.0.1
```

Jangan menutup terminal server selama aplikasi digunakan. Hentikan server dengan `Ctrl+C` pada terminal terkait.

## 7. Pemeriksaan

Daftar route API dapat diperiksa dari direktori backend:

```sh
php artisan route:list --path=api
```

Tes backend:

```sh
php artisan test
```

Build frontend untuk memeriksa kompilasi:

```sh
cd app/frontend
npm run build
```

## 8. Kendala Umum

- **`vite: command not found` atau `package.json` tidak ditemukan:** pastikan terminal berada di `app/frontend`, kemudian jalankan `npm install` dan `npm run dev`.
- **`could not find driver`:** PHP belum memuat ekstensi `pdo_mysql`; aktifkan ekstensi untuk versi PHP yang digunakan CLI.
- **`Access denied for user` atau koneksi database gagal:** pastikan MySQL aktif dan nilai `DB_HOST`, `DB_PORT`, `DB_USERNAME`, serta `DB_PASSWORD` di `app/backend/.env` benar.
- **Database/tabel `classicmodels` tidak ditemukan:** impor ulang script MySQL dari root project seperti pada langkah 3. Perhatikan peringatan bahwa script membuat ulang tabel.
- **Dashboard tidak mendapat respons API:** pastikan backend aktif di port 8000 dan uji `curl http://127.0.0.1:8000/api/dashboard/summary`. Jika backend memakai port/host lain, sesuaikan `VITE_API_URL` di `app/frontend/.env.local`, lalu restart Vite.
- **Port 8000 sedang digunakan:** jalankan backend pada port lain, misalnya `php artisan serve --host=127.0.0.1 --port=8001`, lalu set `VITE_API_URL=http://127.0.0.1:8001/api` dan restart frontend.

