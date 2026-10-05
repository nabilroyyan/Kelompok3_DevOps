<!--
Folder ini adalah PENUNJUK STRUKTUR, bukan lokasi penyimpanan.

MENGAPA: issue awal menetapkan struktur root-level (app/, database/, policy/,
reports/, sbom/, keys/), sedangkan struktur resmi pada README.md repositori
(kelolaan PO) menaruh seluruh artefak di bawah docs/. Keduanya sudah berisi
artefak nyata, sehingga memindahkan isi akan memecah path pada pipeline CI dan
pekerjaan tiga peran lain.

KEPUTUSAN: satu lokasi resmi saja untuk setiap artefak, dan root hanya memuat
berkas penunjuk ini. Dengan begitu tuntutan struktur terpenuhi tanpa
menciptakan dua sumber kebenaran.
-->

# /policy — kebijakan Keamanan sebagai Kode

**Pemilik:** Security Engineer · **Lokasi sebenarnya:** `docs/SEC-ENG/policy/`

## Isi sebenarnya

```text
docs/SEC-ENG/policy/
├── Baseline-Security-Gate-Policy.md   # kebijakan induk + kriteria gate
├── gitleaks.toml                      # aturan secret scanning
├── trivy.yaml + .trivyignore          # aturan SCA & container scan
├── baseline/                          # 01-tls, 02-exposure, 03-logging
├── risk/risk-register.md              # register risiko + evidence
├── pipeline/security-gate.yml         # template workflow (acuan)
├── sonarqube/                         # sonar-project.properties + setup gate
└── scripts/                           # check-infra-policy.sh, verify-deployment.sh
```

## Kontrak untuk Infra

Skrip `check-infra-policy.sh` dijalankan sebagai **Gate 4** pada
`.github/workflows/ci.yml`, dan `verify-deployment.sh` menghasilkan bukti
deployment. Keduanya dipanggil dengan path eksplisit terhadap
`docs/SEC-ENG/policy/`, bukan `policy/` di root.

Template `pipeline/security-gate.yml` adalah acuan; versi yang benar-benar
berjalan ada di `.github/workflows/ci.yml` karena GitHub hanya membaca workflow
dari root.

---

## Jangan taruh berkas artefak di folder ini

Folder ini hanya memuat `README.md` (penunjuk). Bila isi diletakkan di sini,
akan muncul **dua lokasi untuk artefak yang sama** — dan pada kasus `policy/`
serta `reports/`, pipeline CI akan tetap membaca lokasi di `docs/` sehingga
berkas di root menjadi tidak terpakai.

Bila lokasi resmi memang perlu dipindahkan ke root, ubah lebih dulu
`README.md` dan `docs/PO/1. Project-Overview.md` agar tidak ada dua tafsir,
lalu sesuaikan juga path pada `.github/workflows/ci.yml` dan
`docs/INFRA/docker-compose.yml`.
