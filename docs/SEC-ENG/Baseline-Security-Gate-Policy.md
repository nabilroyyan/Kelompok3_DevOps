# Baseline Security Gate Policy — DSS Penjualan Axon

**Milestone 1 · [SEC] Define Baseline Security Gate Policies (Issue #5)** <br>
**Stack:** Laravel (backend), React + Vite (frontend), MySQL, Nginx, Docker Compose.<br> **Tools:** Gitleaks, Trivy, Semgrep, Dependabot. Threshold ini adalah baseline dan ditinjau ulang setelah hasil pemindaian pertama.

## 1. Prinsip

Security Gate adalah pemeriksaan otomatis di GitHub Actions yang **memblokir merge** bila kode, dependensi, image, atau konfigurasi melanggar toleransi PO. Gate yang gagal atau tidak bisa berjalan dianggap **gagal**. Hasil setiap pemindaian disimpan sebagai bukti audit.

## 2. Gate dan Threshold

| Gate | Tool | Aturan FAIL (memblokir) | Toleransi PO |
| :-- | :-- | :-- | :-- |
| **G1 Secret Scan** | Gitleaks | Ada 1 secret di commit atau riwayat Git. Berjalan di *pre-commit* dan CI. | **0** |
| **G2 Dependensi (SCA)** | Trivy `fs` | Ada CVE **Critical** (tanpa pengecualian, patch < 24 jam). | Critical **0** |
| **G3 Kebijakan Container** | `policy/scripts/check-infra-policy.sh` | Container berjalan sebagai root. Database memakai `ports`. Password atau `APP_KEY` literal di compose. `APP_DEBUG=true`. Query mentah yang menyambung variabel. | Root **0**, SQLi **0** |
| **G4 Image Docker** | Trivy `image` | Image `app`, `proxy`, dan `db` memuat CVE Critical. | Critical **0** |
| **G5 SAST** | Semgrep | Ada temuan berseverity ERROR (misalnya SQL Injection) di kode backend atau frontend. Pada tahap awal hasilnya hanya dilaporkan, lalu menjadi pemblokir setelah temuan awal ditangani. | SQLi **0** |

CVE **High, Medium, dan Low** belum memblokir. Hasilnya dilaporkan dan dicatat ke backlog mitigasi.

## 3. Aturan Utama

- **Trivy:** build **GAGAL bila ada Critical**. Critical tanpa patch tetap memblokir (`ignore-unfixed: false`).
- **Gitleaks:** rule bawaan ditambah rule proyek untuk connection string dan password MySQL serta `APP_KEY` Laravel. Pemindaian mencakup seluruh riwayat commit. Secret yang sudah ter-commit wajib **dirotasi**, karena menghapus commit tidak cukup. Hanya `.env.example` tanpa nilai asli yang boleh masuk Git.
- **SQL Injection:** semua query wajib memakai Query Builder/Eloquent dengan binding (parameterized). G3 menggagalkan build bila ada query mentah yang menyambung variabel, dan Pull Request yang melanggar ditolak saat review kode. Semgrep (G5) memindai kode untuk pola SQL Injection dan celah umum lainnya.
- **Semgrep:** memindai kode backend (PHP) dan frontend (JavaScript) memakai rule set OWASP, dan hanya temuan berseverity ERROR yang dihitung. Pada run pertama G5 belum memblokir. Setelah temuan awal ditangani, G5 diaktifkan sebagai pemblokir.
- **Dependabot:** diaktifkan untuk Composer, npm, dan Dockerfile. Dia memberi alert dan membuat PR perbaikan otomatis, tetapi bukan gate pemblokir.
- **Container:** image memakai tag versi spesifik (bukan `latest`), user non-root, `read_only`, `cap_drop: ALL`, dan `no-new-privileges`. Database berada di jaringan `internal` tanpa publish port.
- **Enforcement:** branch `main` mewajibkan Pull Request, 1 approval, dan status **`Security Gate - PASSED`**.

## 4. Konfigurasi di Folder `/policy`

`gitleaks.toml` · `trivy.yaml` (gate Critical) · `pre-commit-config.yaml` · `dependabot.yml` · `scripts/check-infra-policy.sh` (G3) · `pipeline/security-gate.yml` (draf workflow, belum aktif)

## 5. Prasyarat Sebelum Gate Diaktifkan

1. **PHP:** image `app` memakai PHP 8.3, sedangkan dependensi Composer membutuhkan PHP ≥ 8.4.1, sehingga image perlu dinaikkan.
2. **MySQL:** `mysql:8.0` sudah *end-of-life* dan akan ditandai Trivy, jadi perlu versi yang masih didukung.
3. **Akun database:** user aplikasi hanya boleh `SELECT` karena dashboard read-only.
4. **Workflow:** salin `pipeline/security-gate.yml` ke `.github/workflows/` dan `dependabot.yml` ke `.github/`.

## 6. Checklist Issue #5

- [x] Threshold SCA dan Container (Trivy FAIL bila ada Critical): `trivy.yaml`
- [x] Aturan Secret Scanning (Gitleaks/TruffleHog): `gitleaks.toml`
- [x] Konfigurasi awal kebijakan disimpan di folder `/policy`
