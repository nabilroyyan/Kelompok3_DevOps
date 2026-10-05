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

# /sbom — Software Bill of Materials

**Pemilik:** Developer (otomatisasi: Infra) · **Lokasi sebenarnya:** `docs/Dev/axon-devsecops-dss/sbom/`

## Isi sebenarnya

```text
docs/Dev/axon-devsecops-dss/sbom/
├── backend-sbom.cdx.json     # CycloneDX dari composer.lock
└── frontend-sbom.cdx.json    # CycloneDX dari package-lock.json
```

## Cara menghasilkan

```bash
bash docs/INFRA/scripts/generate-sbom.sh
```

Nama berkas di atas persis mengikuti permintaan PO pada butir 2 backlog
`README.md`, dan pipeline mengunggahnya sebagai artefak `sbom-cyclonedx`.

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
