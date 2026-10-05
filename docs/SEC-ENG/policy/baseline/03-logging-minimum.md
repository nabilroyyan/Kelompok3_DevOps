# 03. Logging Minimum

**Peran:** Security menetapkan standar minimum. Platform (Ops) menerapkan pengumpulan, retensi, dan monitoring. Developer memastikan aplikasi tidak membocorkan data lewat log.
**Ancaman TM v1:** T-04 (tidak ada log akses, repudiation), T-07 (error verbose), T-09 (DoS terdeteksi dari pola trafik).
**Mendukung:** prinsip *Evidence as Product* PO.

> Catatan: catatan tulisan tangan menulis "Logging m..." di sisi Security. Dokumen ini membacanya sebagai **Logging minimum**. Mohon dikoreksi jika maksudnya lain.

## 3.1 Peristiwa yang Wajib Dicatat

| # | Peristiwa | Sumber log | Alasan |
| :-- | :-- | :-- | :-- |
| LOG-1 | Setiap request HTTP (access log) | Nginx | Menelusuri sumber trafik mencurigakan (T-04) |
| LOG-2 | Exception dan error aplikasi (detail lengkap hanya di log internal) | Laravel `storage/logs` atau stdout | Pesan ke client tetap generik (T-07) |
| LOG-3 | Request ditolak: 4xx/5xx, 405 (metode terlarang), 429 (rate limit) | Nginx + Laravel | Deteksi probing dan DoS (T-09) |
| LOG-4 | Query lambat / gagal ke database | Laravel (`DB::listen` untuk query di atas ambang) | Deteksi beban berlebih (T-08) |
| LOG-5 | Start/stop dan restart container | Docker / Platform | Jejak deployment |

## 3.2 Field Minimum pada Access Log

`timestamp (UTC, ISO 8601)`, `remote_addr` (IP asli klien, bukan IP proxy), `request_id`, `method`, `path` (tanpa query string sensitif), `status`, `response_time`, `bytes_sent`, `user_agent`.

## 3.3 Yang DILARANG Masuk Log

- Password, `APP_KEY`, token, connection string database.
- Isi data pelanggan mentah (telepon, alamat, `creditLimit`).
- Query string yang memuat data sensitif; query SQL lengkap dengan nilai parameter di produksi.
- Stack trace pada respons HTTP (hanya boleh di log internal).

Kontrol ini melengkapi gate Gitleaks dan SonarQube; pelanggaran ditemukan lewat code review dan pemeriksaan sampel log.

## 3.4 Retensi dan Perlindungan

| Aspek | Baseline |
| :-- | :-- |
| Retensi | Minimal **30 hari** online (sesuaikan kapasitas); log CI dan evidence disimpan sepanjang semester |
| Integritas | Log tidak dapat diubah oleh container aplikasi (volume terpisah / dikirim ke luar container) |
| Akses | Hanya Platform dan Security |
| Waktu | Semua layanan memakai UTC dan NTP host yang sama agar log bisa dikorelasikan |

## 3.5 Konfigurasi Laravel (contoh)

Di `config/logging.php` (default channel ke `stderr`/`daily` untuk container):

```php
'default' => env('LOG_CHANNEL', 'stack'),
'channels' => [
    'stack' => ['driver' => 'stack', 'channels' => ['daily', 'stderr'], 'ignore_exceptions' => false],
    'daily' => ['driver' => 'daily', 'path' => storage_path('logs/laravel.log'), 'level' => env('LOG_LEVEL', 'warning'), 'days' => 30],
    'stderr' => ['driver' => 'monolog', 'handler' => Monolog\Handler\StreamHandler::class,
                 'formatter' => Monolog\Formatter\JsonFormatter::class, 'with' => ['stream' => 'php://stderr']],
],
```

Middleware ringan untuk LOG-3 pada route analitik (opsional jika access log Nginx sudah cukup):

```php
Log::info('dashboard.request', [
    'request_id' => $request->header('X-Request-Id'),
    'ip' => $request->ip(), 'method' => $request->method(),
    'path' => $request->path(), 'status' => $response->getStatusCode(),
]);
```

Pastikan `.env` produksi: `APP_DEBUG=false`, `APP_ENV=production`, `LOG_LEVEL=warning`.

## 3.6 Monitoring (tanggung jawab Platform, kriteria dari Security)

Platform menyiapkan alert minimal untuk: lonjakan 5xx, lonjakan 429/405, banyak 404 dari satu IP (probing), dan container yang restart berulang. Pemilihan tool monitoring ditentukan Platform.

## 3.7 Evidence

Contoh baris access log, potongan `nginx.conf` dengan format log, dan hasil `verify-deployment.sh` dilampirkan sebagai bukti LOG-1 sampai LOG-3.
