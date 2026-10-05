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

# /app — Kode Sumber Aplikasi

**Pemilik:** Developer · **Lokasi sebenarnya:** `docs/Dev/axon-devsecops-dss/app/`

## Isi sebenarnya

```text
docs/Dev/axon-devsecops-dss/app/
├── backend/     # Laravel 13 / PHP 8.4 — RESTful API 12 endpoint (read-only)
└── frontend/    # React 19 + Vite 8 — dashboard DSS
```

## Kontrak untuk Infra

Image container dibangun dari lokasi tersebut oleh
`docs/INFRA/docker/app/Dockerfile` (backend) dan
`docs/INFRA/docker/proxy/Dockerfile` (frontend). Karena itu path pada berkas
Dockerfile **tidak boleh** berubah tanpa menyesuaikan `build.context` pada
`docs/INFRA/docker-compose.yml`.

Infra tidak memodifikasi kode aplikasi (`docs/PO/1.3. Task-Role.md`, Tugas 4).

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
