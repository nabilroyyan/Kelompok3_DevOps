# 01. TLS Baseline

**Peran:** Security menetapkan standar, Platform (Ops) menerapkannya di deployment.
**Ancaman TM v1:** T-03 (data in transit tanpa enkripsi), T-06 (secret tidak boleh lewat kanal tanpa TLS).
**Aset:** A-05 (hasil agregasi yang ditampilkan).

## Standar Minimum (wajib)

| # | Kontrol | Nilai baseline | Cara verifikasi |
| :-- | :-- | :-- | :-- |
| TLS-1 | Versi protokol | **TLS 1.2 dan 1.3 saja**; TLS 1.0/1.1 dan SSL dimatikan | `openssl s_client -tls1_1` harus gagal |
| TLS-2 | HTTP ke HTTPS | Semua request port 80 di-redirect permanen (301/308) ke HTTPS | `curl -I http://host` |
| TLS-3 | HSTS | `Strict-Transport-Security: max-age=31536000; includeSubDomains` | Cek header respons |
| TLS-4 | Cipher suite | Hanya suite AEAD modern (ECDHE + AES-GCM / CHACHA20-POLY1305); tanpa RC4, 3DES, CBC lama, EXPORT | `nmap --script ssl-enum-ciphers` atau `testssl.sh` |
| TLS-5 | Sertifikat | Valid, tidak kedaluwarsa, kunci minimal RSA 2048 atau ECDSA P-256; development boleh self-signed, **produksi wajib CA tepercaya** (mis. Let's Encrypt) | `openssl s_client -connect host:443` |
| TLS-6 | Terminasi TLS | Di reverse proxy (Nginx). Backend Laravel hanya menerima dari proxy, tidak dipublish ke host | Cek `docker-compose.yml` |
| TLS-7 | Laravel sadar proxy | `TrustProxies` diatur agar `https` terdeteksi; paksa skema `https` di produksi | Tautan/asset tidak mixed-content |
| TLS-8 | Cookie/session | `SESSION_SECURE_COOKIE=true`, `SESSION_SAME_SITE=lax` | Cek `.env` produksi |
| TLS-9 | Mixed content | Tidak ada aset `http://`; CDN Bootstrap memakai `https://` + SRI (sudah dicek G4) | Console browser |

## Catatan Implementasi

- Contoh konfigurasi Nginx siap pakai: [`nginx-hardening.conf.example`](nginx-hardening.conf.example).
- Pada jaringan internal container (proxy ke php-fpm, php-fpm ke database) TLS tidak diwajibkan untuk baseline ini karena trafik tidak keluar dari jaringan Docker internal. Jika nanti database dipisah ke host lain, koneksi DB wajib memakai TLS (`sslmode=require`) dan ini ditinjau di TM v2.
- Hanya TLS yang dikonfigurasi di proxy yang dihitung sebagai bukti. Sertifikat self-signed lokal cukup untuk pengujian Milestone ini, tetapi hasilnya dicatat sebagai "development".

## Evidence yang Dihasilkan

`policy/scripts/verify-deployment.sh` menghasilkan laporan yang mencakup TLS-1, TLS-2, TLS-3 (lihat `risk/risk-register.md`, kolom Evidence).
