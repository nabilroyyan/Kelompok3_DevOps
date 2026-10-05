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

# /database — Skema & Data Basis Data

**Pemilik:** Developer · **Lokasi sebenarnya:** `docs/Dev/axon-devsecops-dss/database/`

## Isi sebenarnya

```text
docs/Dev/axon-devsecops-dss/database/
└── axon-postgresql.sql     # dump MySQL `classicmodels` (8 tabel + data)
```

## Catatan penting

Meski bernama `axon-postgresql.sql`, berkas itu **adalah dump MySQL**
(backtick, `int(11)`, `ENGINE=`). Percobaan porting ke PostgreSQL tidak valid.
Bukti lengkap ada di `docs/INFRA/docs/laporan-infra.md` §6.2.

## Kontrak untuk Infra

Dump di-mount **read-only** ke `/docker-entrypoint-initdb.d/10-classicmodels.sql`
pada `docs/INFRA/docker-compose.yml`, lalu disusul
`docker/db/20-app-user-privileges.sh` yang membatasi user aplikasi menjadi
`SELECT` saja.

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
