# Baseline Security Gate Policy: DSS Penjualan Axon

**Milestone 1: [SEC] Define Baseline Security Gate Policies (Issue #5)**
**Versi:** 1.0 | **Acuan:** Threat Modeling v1 (STRIDE) | **Tools:** SonarQube, Trivy, Gitleaks

> **Stack:** Backend **Laravel** (PHP) dan Frontend **HTML5 + Bootstrap 5**, database PostgreSQL, seluruhnya dalam Docker. Threshold di sini adalah **baseline** dan akan ditinjau ulang pada Threat Modeling v2 setelah implementasi berjalan.

---

## 1. Tujuan dan Prinsip

Security Gate adalah pemeriksaan otomatis di pipeline CI/CD yang **memblokir merge/deploy** bila kode, dependensi, image, atau konfigurasi melanggar kebijakan. Setiap gate dipetakan ke ancaman pada TM v1.

Prinsip:
1. **Fail closed:** gate yang gagal atau tidak bisa dijalankan dianggap gagal.
2. **Zero tolerance** untuk kredensial bocor, SQL Injection, dan privilege container berlebih (kebijakan PO).
3. **Evidence as product:** setiap gate menghasilkan artefak (laporan SARIF, SBOM, log) yang disimpan sebagai bukti audit.
4. **Pengecualian harus tertulis:** alasan, pemilik, tanggal kedaluwarsa, dan persetujuan PO/Security.

## 1.1 Pembagian Peran dan Tugas Security

Kebijakan ini dijalankan bersama tiga peran. Tugas Security dalam Milestone 1 adalah **TLS baseline, Exposure Control, dan Logging minimum**, lalu menilai risiko dengan alur **Pre-Risk → Evidence → Residual Risk**.

| Peran | Tanggung jawab | Keterkaitan dengan dokumen ini |
| :-- | :-- | :-- |
| **Developer (App)** | Spesifikasi aplikasi: port, header, dan endpoint | Menyerahkan daftar route, port, dan header yang diset aplikasi (input bagi `02-exposure-control.md`) |
| **Platform (Ops)** | Deployment, log, monitoring | Menerapkan baseline di Nginx/Docker Compose dan menjalankan pengumpulan log serta alert |
| **Security (Sec)** | TLS baseline, Exposure Control, Logging minimum | Menetapkan standar (`baseline/`), menjalankan gate CI, memverifikasi, dan mengelola risk register |

```
Pre-Risk (TM v1)  →  Evidence (gate CI + verify-deployment.sh)  →  Residual Risk (risk-register.md)
```

| Tugas Security | Dokumen | Ancaman TM v1 |
| :-- | :-- | :-- |
| TLS baseline | [`baseline/01-tls-baseline.md`](baseline/01-tls-baseline.md) | T-03 |
| Exposure Control (port, endpoint, header) | [`baseline/02-exposure-control.md`](baseline/02-exposure-control.md) | T-02, T-05, T-07, T-09, T-10 |
| Logging minimum | [`baseline/03-logging-minimum.md`](baseline/03-logging-minimum.md) | T-04, T-07, T-09 |
| Penilaian risiko dan evidence | [`risk/risk-register.md`](risk/risk-register.md) | T-01 s.d. T-11 |

Contoh konfigurasi Nginx yang memenuhi ketiganya: [`baseline/nginx-hardening.conf.example`](baseline/nginx-hardening.conf.example). Bukti penerapan dihasilkan oleh `scripts/verify-deployment.sh` ke folder `evidence/`.

## 2. Ringkasan Gate

| Gate | Tool | Kondisi FAIL (memblokir) | Ancaman TM v1 | Aset |
| :-- | :-- | :-- | :-- | :-- |
| G1 Secret Scan | Gitleaks | Ada 1 temuan secret (seluruh riwayat commit) | T-06 | A-01, A-06 |
| G2 SAST | **SonarQube** | Quality Gate `Axon-DSS-Baseline` merah (lihat bagian 3) | T-02, T-06, T-07 | A-01, A-02, A-03 |
| G3 SCA + SBOM | Trivy `fs` | Ada kerentanan **CRITICAL** pada dependensi | T-11 | A-06 |
| G4 Infra & Laravel Policy | `check-infra-policy.sh` | DB mem-publish port ke host; password/`APP_KEY` literal; `.env` ter-track Git; `APP_DEBUG=true` di konfigurasi deploy; Dockerfile tanpa `USER` non-root; raw query Laravel dengan interpolasi variabel; aset CDN Bootstrap tanpa SRI | T-02, T-05, T-06, T-07, T-10, T-11 | A-01, A-02, A-03, A-06 |
| G5 Image Scan | Trivy `image` | Ada kerentanan **CRITICAL** atau misconfig CRITICAL pada image | T-10, T-11 | A-06 |

Temuan **HIGH** pada SCA tidak memblokir tetapi dilaporkan di log job untuk triase (target perbaikan: sebelum rilis akhir).

## 3. Kebijakan SonarQube (SAST)

Quality Gate kustom **`Axon-DSS-Baseline`** dinilai pada **new code** (perubahan terhadap `main`), agar tim tidak terblokir utang lama namun kode baru tetap ketat.

| Metrik (new code) | Kondisi lulus | Alasan / kaitan TM v1 |
| :-- | :-- | :-- |
| Security Rating | **A** (nol vulnerability baru) | T-02 SQL Injection, T-07 error verbose |
| Security Hotspots Reviewed | **100%** | Hotspot seperti query SQL dinamis & kredensial wajib ditinjau manusia (T-02, T-06) |
| Reliability Rating | **A** | Kestabilan API analitik (T-08) |
| Maintainability Rating | **A** | Mencegah utang teknis pada kode baru |
| Coverage | **≥ 70%** | Menjamin logika agregasi (integritas A-05) teruji |
| Duplicated Lines | **≤ 3%** | Kualitas dasar |

Konfigurasi untuk Laravel:
- Analisis mencakup `app`, `routes`, `resources` (Blade/JS/CSS), `config`, `database`, `public`; folder `vendor`, `storage`, `node_modules`, dan file `*.min.*` dikecualikan.
- Coverage berasal dari **PHPUnit** (`coverage/clover.xml`), dihasilkan di job SAST sebelum scan. Uji memakai SQLite in-memory dan `.env.example` sehingga tidak butuh secret nyata.

Batasan penting: **SonarQube Community Edition tidak menyertakan taint analysis** (pelacakan input pengguna sampai ke query SQL). Karena T-02 berisiko Kritis, kekurangan ini ditutup oleh dua lapis:
1. Guard di `check-infra-policy.sh` yang menggagalkan build bila ada `DB::select/raw`, `whereRaw`, `selectRaw`, `orderByRaw`, dll. yang menyambung atau menginterpolasi variabel (wajib memakai binding `?`).
2. Bila kampus/tim memakai Developer Edition atau SonarCloud, taint analysis PHP aktif otomatis dan lapisan ini menjadi cadangan.

Aturan tambahan:
- Rule bawaan yang relevan harus aktif pada Quality Profile PHP: SQL Injection, hardcoded credentials, dan informasi sensitif terekspos. Nomor rule diverifikasi di UI SonarQube sesuai versi server.
- Menandai issue sebagai *False Positive / Won't Fix* hanya oleh reviewer selain penulis kode, dengan komentar alasan.
- Token: `SONAR_TOKEN` dan `SONAR_HOST_URL` hanya disimpan di GitHub Secrets.

## 4. Kebijakan Trivy (SCA & Container)

- **Threshold: FAIL jika ada temuan CRITICAL** (sesuai Issue #5), dengan `ignore-unfixed: false` sehingga Critical tanpa patch tetap memblokir dan hanya bisa lolos lewat `.trivyignore` yang disetujui.
- Scanner aktif: `vuln` dan `misconfig` (mendeteksi Dockerfile yang berjalan sebagai root, T-10).
- **SBOM** format CycloneDX dihasilkan pada setiap run dan disimpan sebagai artefak (T-11).
- Base image harus versi tertentu (bukan `latest`), disarankan varian slim/alpine untuk mengurangi permukaan serangan (mis. `php:8.3-fpm-alpine`).
- **`composer.lock` wajib di-commit** karena Trivy membaca dependensi PHP dari file tersebut. `composer audit` dijalankan sebagai informasi pembanding (tidak memblokir).
- **Bootstrap 5:** bila dimuat dari CDN, setiap tag `<script>`/`<link rel="stylesheet">` wajib memakai atribut `integrity` (SRI) dan `crossorigin="anonymous"`, atau aset di-host lokal. Google Fonts dikecualikan karena tidak mendukung SRI. Ini mengurangi risiko supply chain pada sisi frontend (T-11).

## 5. Kebijakan Secret Scanning

- Tool utama: **Gitleaks** dengan rule bawaan ditambah rule proyek (connection string PostgreSQL, `DB_PASSWORD`, token SonarQube). TruffleHog boleh dipakai sebagai pemindai kedua (opsional, mode `--only-verified`).
- Pemindaian mencakup **seluruh riwayat Git** (`fetch-depth: 0`), bukan hanya commit terakhir.
- Secret yang terlanjur ter-commit: **rotasi kredensial segera**, karena menghapus commit tidak cukup.
- Nilai kredensial hanya lewat environment variable / GitHub Secrets; `.env` masuk `.gitignore` (G4 memeriksa file ini tidak ter-track), hanya `.env.example` tanpa nilai asli yang boleh di-commit.
- `APP_KEY` Laravel diperlakukan sebagai secret (dipakai untuk enkripsi dan signing cookie); rule khusus Gitleaks mendeteksinya. Bila bocor, jalankan `php artisan key:generate` dan deploy ulang.

## 6. Pemetaan Lengkap ke Threat Modeling v1

| Ancaman | Ditangani gate otomatis | Ditangani di luar pipeline (kontrol lain) |
| :-- | :-- | :-- |
| T-01 Spoofing | - | Diterima (tidak ada sistem akun, di luar cakupan PO) |
| T-02 SQL Injection | G2 (Security Rating A, hotspot 100%), G4 (guard raw query) | Query Builder/Eloquent dengan binding, validasi input lewat Form Request |
| T-03 Data in transit | - (bukan gate CI; dibuktikan lewat `verify-deployment.sh`) | TLS baseline (`baseline/01`), HSTS, `URL::forceScheme('https')`; DAST di TM v2 |
| T-04 Tidak ada log | - (dibuktikan lewat sampel log) | Logging minimum (`baseline/03`): access log JSON Nginx + log Laravel |
| T-05 DB terekspos | G4 (larangan `ports` pada DB) | Isolasi jaringan container (network internal) |
| T-06 Kredensial bocor | G1, G2, G4 | `.env`/GitHub Secrets, `APP_KEY` di luar repo |
| T-07 Error verbose | G2, G4 (`APP_DEBUG=true` ditolak) | `APP_DEBUG=false`, `APP_ENV=production`, halaman error generik |
| T-08, T-09 DoS | - (dibuktikan lewat konfigurasi dan uji 429) | Nginx `limit_req` + middleware `throttle` (`baseline/02`, EXP-5, EXP-6) |
| T-10 Container root | G4 (`USER` non-root), G5 (misconfig) | php-fpm sebagai `www-data`, read-only filesystem bila memungkinkan |
| T-11 Supply chain | G3, G4 (SRI Bootstrap), G5, SBOM | Commit `composer.lock`, pin versi dependensi & base image |

Ancaman **T-01, T-03, T-04, T-08, T-09** tidak bisa dicakup gate SAST/SCA. Untuk T-03, T-04, T-09 kontrolnya ada di `baseline/` dan dibuktikan lewat `verify-deployment.sh` serta sampel log. T-08 baru bisa dinilai setelah ada uji beban, dan DAST (mis. OWASP ZAP) direkomendasikan pada TM v2. Karena itu residual T-08 ditargetkan Sedang di risk register.

## 7. Enforcement (Branch Protection)

Aktifkan pada branch `main` (Settings, Branches):
- Require a pull request before merging (minimal 1 approval).
- Require status checks: **`Security Gate - PASSED`** (job ringkasan yang bergantung pada semua gate).
- Require branches to be up to date; larang force push.

## 8. Manajemen Pengecualian

Setiap pengecualian (`.trivyignore`, allowlist Gitleaks, false positive SonarQube) wajib memuat: alasan teknis, pemilik, **tanggal kedaluwarsa maksimal 90 hari**, dan persetujuan PO/Security. Pengecualian dilarang untuk temuan T-06 (secret asli) dan SQL Injection terkonfirmasi.

## 9. Struktur Folder `/policy`

```
policy/
├── README.md                        # dokumen ini
├── gitleaks.toml                    # aturan secret scanning
├── trivy.yaml                       # threshold SCA & container
├── .trivyignore                     # pengecualian (kosong pada baseline)
├── sonarqube/
│   ├── sonar-project.properties     # konfigurasi analisis
│   └── setup-quality-gate.sh        # membuat Quality Gate via API
├── baseline/                        # tugas Security
│   ├── 01-tls-baseline.md
│   ├── 02-exposure-control.md
│   ├── 03-logging-minimum.md
│   └── nginx-hardening.conf.example
├── risk/
│   └── risk-register.md             # Pre-Risk → Evidence → Residual Risk
├── scripts/
│   ├── check-infra-policy.sh        # gate CI: T-02, T-05, T-06, T-07, T-10, T-11
│   └── verify-deployment.sh         # uji deployment + hasilkan evidence/ (TLS, header, endpoint, port)
└── pipeline/
    └── security-gate.yml            # salin ke .github/workflows/
```

## 10. Langkah Aktivasi

1. Siapkan server SonarQube (Docker atau SonarCloud) dan buat project `axon-dss-dashboard`.
2. Jalankan `setup-quality-gate.sh` sekali dengan token admin.
3. Tambahkan secrets `SONAR_TOKEN` dan `SONAR_HOST_URL` di GitHub (Settings, Secrets and variables, Actions).
4. Salin `policy/pipeline/security-gate.yml` ke `.github/workflows/security-gate.yml`.
5. Aktifkan branch protection (bagian 7).
6. Pastikan repo Laravel memiliki `composer.lock`, `phpunit.xml`, dan `.env.example`; sesuaikan versi PHP di workflow (`php-version`).
7. Minta Developer menyerahkan daftar port, route, dan header; minta Platform menerapkan `baseline/nginx-hardening.conf.example`.
8. Setelah deploy, jalankan `bash policy/scripts/verify-deployment.sh https://<host> <db-host>` dari luar jaringan Docker, simpan hasil `evidence/`, lalu isi kolom Residual di risk register.
9. Dokumentasikan detail stack (Laravel + Bootstrap) pada Threat Modeling v2.

## 11. Checklist Acceptance Issue #5

- [ ] Threshold SCA & Container (Trivy: FAIL jika ada Critical): `trivy.yaml`
- [ ] Aturan Secret Scanning (Gitleaks/TruffleHog): `gitleaks.toml`
- [ ] Konfigurasi awal kebijakan di folder `/policy`
- [ ] SonarQube Quality Gate & konfigurasi SAST: `sonarqube/`
- [ ] Pemetaan ke ancaman TM v1 (bagian 6)
- [ ] Tugas Security: TLS baseline, Exposure Control, Logging minimum (`baseline/`)
- [ ] Alur Pre-Risk → Evidence → Residual Risk (`risk/risk-register.md`, `verify-deployment.sh`)
- [ ] Evidence dan Residual Risk final: diisi setelah Developer dan Platform selesai menerapkan (belum bisa dibuktikan pada tahap perencanaan)
