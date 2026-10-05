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

# /reports — Bukti Hasil Pemindaian Keamanan

**Pemilik:** Security Engineer · **Lokasi sebenarnya:** `docs/SEC-ENG/reports/`

## Isi sebenarnya

```text
docs/SEC-ENG/reports/
├── gitleaks.sarif     # temuan secret (dapat diunggah ke tab Security GitHub)
├── trivy-fs.sarif     # temuan CVE/misconfig dependensi
├── trivy-fs.json      # arsip bukti terstruktur
└── gates-local-*.log  # log lengkap seluruh gate
```

Lokasi ini ditunjuk langsung oleh butir 3 backlog PO pada `README.md`.

## Cara mengisi

```bash
REPORTS_DIR=docs/SEC-ENG/reports bash docs/INFRA/scripts/run-gates-local.sh
```

Berkas di folder ini **memang dimaksudkan ter-commit** sebagai bukti audit,
sehingga sengaja tidak diabaikan oleh `.gitignore` di root.

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
