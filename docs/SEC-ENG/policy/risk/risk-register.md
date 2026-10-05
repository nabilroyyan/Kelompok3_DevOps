# Risk Register: Pre-Risk → Evidence → Residual Risk

**Peran Security.** Alur kerja: nilai **Pre-Risk** (risiko sebelum kontrol, dari TM v1), kumpulkan **Evidence** bahwa kontrol benar-benar berjalan, lalu tetapkan **Residual Risk** (risiko yang tersisa).

```
Pre-Risk (TM v1)  →  Evidence (bukti kontrol)  →  Residual Risk (sisa risiko)
```

## Aturan

1. **Pre-Risk** diambil apa adanya dari tabel STRIDE di TM v1.
2. **Evidence** adalah artefak nyata: laporan gate CI (SARIF, Quality Gate Sonar, Trivy, SBOM), keluaran `verify-deployment.sh`, potongan konfigurasi, atau sampel log. Tanpa evidence, status tetap "Belum terverifikasi".
3. **Residual Risk hanya boleh diturunkan dari Pre-Risk jika evidence ada.** Kolom Residual di bawah berisi **target** yang diharapkan; nilai final diisi Security setelah implementasi berjalan.
4. Risiko yang tersisa Sedang atau lebih tinggi wajib punya keputusan: mitigasi tambahan atau **diterima secara tertulis oleh PO**.
5. Register ditinjau ulang saat Threat Modeling v2.

## Skala Residual Risk

Rendah (dapat diterima), Sedang (perlu rencana/persetujuan PO), Tinggi (tidak dapat diterima, blok rilis).

## Register

| ID | Ancaman (TM v1) | Pre-Risk | Kontrol | Penanggung jawab | Evidence yang diminta | Status | Target Residual | Residual final |
| :-- | :-- | :--: | :-- | :-- | :-- | :-- | :--: | :--: |
| T-01 | Spoofing (tidak ada akun) | n/a di TM v1 (diusulkan Rendah) | Diterima, di luar cakupan PO; semua endpoint read-only | PO / Security | Catatan penerimaan risiko PO | Belum terverifikasi | Rendah | - |
| T-02 | SQL Injection | **Kritis** | Parameterized query; Sonar Security Rating A + hotspot 100%; guard raw query (G4); whitelist parameter filter | Developer, Security | Laporan Quality Gate Sonar, log G4, daftar route + validasi | Belum terverifikasi | Rendah | - |
| T-03 | Data in transit tanpa TLS | Tinggi | TLS baseline (TLS-1..9), HSTS | Platform, Security | `verify-deployment.sh` (bagian TLS), hasil testssl/openssl | Belum terverifikasi | Rendah | - |
| T-04 | Tidak ada log akses | Sedang | Logging minimum (LOG-1..5) | Platform, Developer | Contoh access log JSON, konfigurasi log_format, sampel log Laravel | Belum terverifikasi | Rendah | - |
| T-05 | Database terekspos | **Kritis** | Tanpa `ports` pada DB, network internal | Platform, Security | Log G4, `verify-deployment.sh` (uji port), `docker-compose.yml` | Belum terverifikasi | Rendah | - |
| T-06 | Kredensial bocor | **Kritis** | Gitleaks seluruh riwayat, `.env` tidak ter-track, rule APP_KEY | Semua peran, Security | Laporan Gitleaks (SARIF), log G4 | Belum terverifikasi | Rendah | - |
| T-07 | Error verbose | Sedang | `APP_DEBUG=false`, halaman error generik, cek G4 | Developer, Security | Log G4, uji manual respons error produksi | Belum terverifikasi | Rendah | - |
| T-08 | DoS lewat query berat | Sedang | Validasi rentang filter, log query lambat | Developer, Platform | Kode validasi, log query lambat, uji beban ringan | Belum terverifikasi | Sedang | - |
| T-09 | DoS tanpa rate limit | Sedang | Nginx `limit_req` + `throttle` Laravel | Platform, Developer | Konfigurasi Nginx, uji beruntun yang menghasilkan 429 | Belum terverifikasi | Rendah | - |
| T-10 | Container berjalan sebagai root | Tinggi | `USER` non-root, Trivy misconfig, cek G4 | Platform, Security | Log G4, Trivy image scan, `docker inspect` user | Belum terverifikasi | Rendah | - |
| T-11 | Supply chain | Tinggi | Trivy FAIL pada CRITICAL, SBOM CycloneDX, SRI CDN, `composer.lock` | Developer, Security | Laporan Trivy, `sbom.cdx.json`, log G4 | Belum terverifikasi | Rendah | - |

**Mengapa T-08 ditargetkan Sedang:** tidak ada gate otomatis yang membuktikan ketahanan terhadap query berat. Residual baru bisa diturunkan setelah ada uji beban (mis. k6/ab) atau DAST pada TM v2.

## Template Entri Evidence

```
ID Risiko   : T-xx
Tanggal     : YYYY-MM-DD   Pelaksana: <nama>
Kontrol     : <nama kontrol / ID baseline>
Cara uji    : <perintah atau job CI>
Artefak     : <path/ tautan ke laporan>   (mis. evidence/verify-2026....txt, run GitHub Actions #n)
Hasil       : PASS / FAIL
Pre-Risk    : <nilai>      Residual: <nilai>
Catatan     : <temuan, pengecualian yang disetujui, tindak lanjut>
```

Folder `evidence/` dibuat otomatis oleh `verify-deployment.sh`; laporan dari CI (Gitleaks SARIF, SBOM) tersedia sebagai artefak job GitHub Actions dan disalin/diberi tautan di sini.
