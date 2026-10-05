# 02. Exposure Control

**Peran:** Developer menyerahkan spesifikasi aplikasi (port, header, endpoint). Security menetapkan apa yang **boleh** terekspos. Platform menerapkan di deployment.
**Ancaman TM v1:** T-05 (DB terekspos), T-02/T-07 (permukaan serangan aplikasi), T-09 (DoS), T-10 (privilege container).

## 2.1 Matriks Port

| Layanan | Port container | Dipublish ke host/publik? | Keterangan |
| :-- | :-- | :-- | :-- |
| Nginx (reverse proxy) | 80, 443 | **Ya** (satu-satunya pintu masuk) | 80 hanya untuk redirect ke 443 |
| Laravel (php-fpm) | 9000 | **Tidak** | Hanya dijangkau Nginx lewat jaringan internal |
| PostgreSQL | 5432 | **Tidak (wajib)** | Zero tolerance; dicek otomatis oleh G4 |
| SonarQube / tool lain | - | Tidak di lingkungan aplikasi | Dijalankan terpisah dari stack aplikasi |

Aturan jaringan Docker: database dan php-fpm berada di network `internal: true`; hanya Nginx yang juga tersambung ke network publik.

## 2.2 Kontrol Endpoint (dashboard read-only)

Sesuai batasan PO (display-only, tanpa transaksi dan tanpa login):

| # | Kontrol | Baseline |
| :-- | :-- | :-- |
| EXP-1 | Metode HTTP | Hanya **GET dan HEAD**. POST/PUT/PATCH/DELETE ditolak (405) di tingkat proxy |
| EXP-2 | Daftar endpoint | Developer menyerahkan daftar route resmi (modul Revenue, Order Fulfillment, Inventory Health, Customer Intelligence). Route di luar daftar tidak boleh ada |
| EXP-3 | Path sensitif | Wajib 403/404: `/.env`, `/.git/`, `/storage/`, `/vendor/`, `/composer.*`, `/phpinfo.php`, `/telescope`, `/horizon`, `/_ignition`, `/debugbar` |
| EXP-4 | Paket debug | `barryvdh/laravel-debugbar`, `laravel/telescope`, dan sejenisnya hanya di `require-dev`, tidak ikut di image produksi (`composer install --no-dev`) |
| EXP-5 | Rate limiting | Nginx `limit_req` dan middleware Laravel `throttle` pada route API (T-09) |
| EXP-6 | Pembatasan query | Parameter filter (tahun/bulan/kategori) divalidasi dengan whitelist dan rentang maksimal (T-08) |
| EXP-7 | Data sensitif di response | Endpoint tidak mengembalikan kolom mentah sensitif: `customers.phone`, alamat lengkap, `creditLimit`, `employees.email`, `products.buyPrice`. Hanya agregasi (A-02, A-03, A-07) |
| EXP-8 | Versi software | `server_tokens off` (Nginx), `expose_php = Off` (PHP); tidak ada header `Server` berversi atau `X-Powered-By` |

## 2.3 Security Header Wajib

| Header | Nilai baseline | Catatan |
| :-- | :-- | :-- |
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains` | Lihat TLS-3 |
| `X-Content-Type-Options` | `nosniff` | |
| `X-Frame-Options` | `DENY` | Mencegah clickjacking |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | |
| `Permissions-Policy` | `geolocation=(), microphone=(), camera=()` | |
| `Content-Security-Policy` | `default-src 'self'; script-src 'self' https://cdn.jsdelivr.net; style-src 'self' https://cdn.jsdelivr.net 'unsafe-inline'; img-src 'self' data:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'` | Sesuaikan dengan sumber aset sebenarnya. `unsafe-inline` pada style adalah kompromi untuk library grafik; Developer diminta menghilangkannya bila memungkinkan |

## 2.4 Alur Serah-Terima (sesuai pembagian peran)

1. **Developer** mengisi spesifikasi: daftar port, route/endpoint, header yang sudah diset aplikasi.
2. **Security** membandingkan dengan baseline ini dan mencatat temuan sebagai Pre-Risk.
3. **Platform** menerapkan di Nginx dan `docker-compose.yml`.
4. **Security** menjalankan `verify-deployment.sh` dan menyimpan hasilnya sebagai Evidence, lalu menetapkan Residual Risk.

## 2.5 Contoh Fragmen `docker-compose.yml` yang Sesuai

```yaml
services:
  nginx:
    image: nginx:1.27-alpine
    ports: ["80:80", "443:443"]
    networks: [public, internal]
  app:                 # Laravel php-fpm, tanpa ports
    build: .
    networks: [internal]
  db:                  # PostgreSQL, tanpa ports
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    networks: [internal]
networks:
  public: {}
  internal:
    internal: true
```
