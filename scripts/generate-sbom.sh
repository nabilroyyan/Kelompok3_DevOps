#!/usr/bin/env bash
# =============================================================================
# Axon DSS — pembuat artefak SBOM (CycloneDX)   [peran Infra]
#
# MENGAPA
#   docs/PO/1.3. Task-Role.md (Tugas 3 Developer) mewajibkan SBOM standar
#   industri, dan docs/PO/2.1 Developer Analysis Result.md menemukan bahwa
#   artefak ini BELUM ADA (Prioritas P1). Skrip ini menyediakan jalur otomatis
#   dari sisi Infra sehingga SBOM bisa dihasilkan berulang tanpa langkah manual,
#   lalu ikut diunggah sebagai artefak pipeline.
#
#   Kepemilikan isi SBOM tetap milik Developer (Tugas 3 mereka); Infra hanya
#   menyediakan otomatisasinya dan tidak mengubah composer.json/package.json.
#
# MENGAPA MEMAKAI TRIVY
#   Trivy sudah dipakai di pipeline untuk SCA (policy/trivy.yaml), sehingga SBOM
#   dihasilkan tool yang sama dengan yang memindai dependensi — tidak menambah
#   dependensi baru ke proyek Developer (mis. plugin composer) dan tidak
#   menambah rantai pasok baru yang harus diaudit.
#
# PEMAKAIAN
#   bash scripts/generate-sbom.sh                  # tulis ke folder sbom/
#   OUT_DIR=/tmp/sbom bash scripts/generate-sbom.sh
#   bash scripts/generate-sbom.sh --stdout backend  # cetak ke layar
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

APP_DIR="${REPO_ROOT}/app"
BACKEND_DIR="${APP_DIR}/backend"
FRONTEND_DIR="${APP_DIR}/frontend"
# Path keluaran mengikuti struktur resmi pada README.md repositori (folder sbom/ di root).
OUT_DIR="${OUT_DIR:-${REPO_ROOT}/sbom}"

TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:0.58.0}"

STDOUT_MODE=0
TARGET="all"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --stdout) STDOUT_MODE=1 ;;
        backend|frontend|all) TARGET="$1" ;;
        *) echo "Argumen tidak dikenal: $1" >&2; exit 2 ;;
    esac
    shift
done

# Trivy dijalankan sebagai container agar tidak perlu memasangnya di host.
# Repo di-mount read-only; folder keluaran di-mount read-write.
trivy() {
    docker run --rm \
        -v "${REPO_ROOT}:/src:ro" \
        -v "${OUT_DIR}:/out" \
        -w /src \
        "${TRIVY_IMAGE}" "$@"
}

command -v docker >/dev/null || { echo "Docker tidak ditemukan." >&2; exit 1; }

declare -a GENERATED=()

emit() { # label, path sumber (relatif repo), path keluaran
    local label="$1" source="$2" out="$3"
    echo "[sbom] Membuat SBOM ${label} dari ${source}"
    # --list-all-pkgs wajib: tanpa itu Trivy hanya mencantumkan paket yang
    # punya kerentanan, sehingga hasilnya bukan inventaris lengkap dan tidak
    # layak disebut SBOM.
    if [[ "${STDOUT_MODE}" == "1" ]]; then
        trivy fs --quiet --format cyclonedx --scanners vuln --list-all-pkgs "${source}" 2>/dev/null
        return
    fi
    trivy fs --quiet --format cyclonedx --scanners vuln --list-all-pkgs \
        --output "/out/$(basename "${out}")" "${source}"
    GENERATED+=("${out}")
}

if [[ "${STDOUT_MODE}" == "1" ]]; then
    [[ "${TARGET}" == "all" || "${TARGET}" == "backend" ]] && emit "backend" "app/backend" ""
    [[ "${TARGET}" == "all" || "${TARGET}" == "frontend" ]] && emit "frontend" "app/frontend" ""
    exit 0
fi

mkdir -p "${OUT_DIR}"

case "${TARGET}" in
    all)
        emit "backend"  "app/backend"  "${OUT_DIR}/backend-sbom.cdx.json"
        emit "frontend" "app/frontend" "${OUT_DIR}/frontend-sbom.cdx.json"
        ;;
    backend)
        emit "backend"  "app/backend"  "${OUT_DIR}/backend-sbom.cdx.json"
        ;;
    frontend)
        emit "frontend" "app/frontend" "${OUT_DIR}/frontend-sbom.cdx.json"
        ;;
esac

echo
echo "[sbom] Ringkasan komponen yang terdaftar"
python3 - "${GENERATED[@]}" <<'PY'
import json, sys, pathlib
for path in sys.argv[1:]:
    p = pathlib.Path(path)
    if not p.exists():
        print(f"  {p.name}: TIDAK ADA")
        continue
    data = json.loads(p.read_text())
    print(f"  {p.name}: {len(data.get('components', []))} komponen, "
          f"specVersion {data.get('specVersion')}, bomFormat {data.get('bomFormat')}")
PY

echo
echo "[sbom] Selesai. Berkas ada di: ${OUT_DIR}"
