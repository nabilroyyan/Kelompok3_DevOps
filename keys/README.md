# /keys — Kunci Verifikasi & Tanda Tangan

**Pemilik pengelolaan folder:** Infrastructure Engineer
**Pemilik isi kunci:** Security Engineer
**Lokasi:** `keys/` — **folder ini adalah lokasi resmi**, bukan sekadar penunjuk

## Mengapa folder ini ada di root

Dari seluruh struktur root-level pada issue awal (`app/`, `database/`,
`policy/`, `reports/`, `sbom/`, `keys/`), hanya `keys/` yang belum punya
padanan di dalam `docs/`. Lima folder lainnya sudah berisi artefak nyata di
bawah `docs/`, sehingga root hanya memuat berkas penunjuk agar tidak muncul dua
sumber kebenaran.

Karena belum ada artefak tanda tangan pada proyek ini, `keys/` tidak
menimbulkan duplikasi dan dapat dipakai langsung sebagai lokasi baku.

## ATURAN KERAS

`docs/PO/1. Project-Overview.md` menuliskan pada struktur direktorinya:

> `keys/` — Kunci verifikasi/tanda tangan (**PUBLIC keys only! DILARANG private keys**)

Konsekuensi teknis:

| Berkas | Boleh di-commit? | Ditangani oleh |
| :--- | :---: | :--- |
| `<nama>.pub`, `*.pub` | ✅ | — |
| `*.key`, `*.p12`, `*.pfx`, `*.jks`, `*.keystore` | ❌ | diblokir `.gitignore` root |
| `id_rsa*`, `id_ed25519*` (tanpa `.pub`) | ❌ | diblokir `.gitignore` root |
| `service-account*.json`, `*credentials*.json` | ❌ | diblokir `.gitignore` root |

`.gitignore` root juga menyediakan pengecualian `!*.pub`, `!id_rsa.pub`, dan
`!id_ed25519.pub` agar kunci publik tetap dapat di-commit.

## Isi yang diharapkan

```text
keys/
├── README.md                     # berkas ini
└── <nama-kunci>.pub              # kunci publik untuk verifikasi artefak
```

Belum ada kunci yang perlu disimpan: proyek ini belum menandatangani image
maupun artefak rilis, dan `docs/PO/1.3. Task-Role.md` belum menetapkan
mekanisme signing. Folder ini disiapkan agar lokasinya baku sejak awal
sehingga tidak ada kebingungan saat signing mulai dipakai (mis. verifikasi
SBOM atau attestation).

## Bila signing mulai dipakai

1. Buat pasangan kunci **di luar repositori** (mesin lokal atau secret store),
   dan jangan pernah menyalin private key ke folder ini.
2. Simpan hanya kunci publik di sini.
3. Catat pemilik kunci, tanggal dibuat, dan masa berlakunya — mengikuti pola
   register pada `docs/SEC-ENG/policy/risk/risk-register.md`.
4. Tambahkan langkah verifikasi ke `.github/workflows/ci.yml` agar kunci ini
   benar-benar terpakai, bukan sekadar tersimpan.

## Jangan taruh private key atau secrets di sini

Folder ini berada di repositori publik. Sekali private key ter-commit, ia harus
dianggap bocor dan wajib dirotasi — bukan sekadar dihapus. Aturan ini sejalan
dengan Zero Tolerance kredensial bocor pada `docs/PO/1.2 Risk.md` dan ditopang
**Gate 1 (Gitleaks)** pada pipeline.
