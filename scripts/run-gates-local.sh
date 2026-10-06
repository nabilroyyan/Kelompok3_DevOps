#!/usr/bin/env bash
# =============================================================================
# Axon DSS — menjalankan Security Gate secara lokal   [peran Infra]
#
# MENGAPA
#   Prinsip yang dipakai di Bab 1 dan Bab 3: gate yang berjalan di pipeline
#   harus bisa direproduksi di mesin developer. Kalau hasil lokal dan pipeline
#   berbeda, orang berhenti mempercayai gate-nya. Skrip ini menjalankan gate
#   yang sama (versi lokal, tanpa GitHub Actions) dengan tool yang sama.
#
# GATE YANG DIJALANKAN
#   Gate 1  Secret scan  : Gitleaks
#   Gate 2  SCA + SBOM   : Trivy fs (+ SBOM CycloneDX)
#   Gate 3  Infra policy : check-infra-policy.sh milik Security + Hadolint
#   Gate 4  Container    : docker compose build + Trivy image (butuh WITH_IMAGE=1)
#   Gate 5  SAST         : Semgrep (ruleset p/php, p/javascript,
#                          p/owasp-top-ten — mengikuti pilihan Security Engineer)
#
#   Penomoran gate mengikuti template policy/pipeline/security-gate.yml.
#   Seluruh gate di atas kini dapat direproduksi lokal. Semgrep menggantikan
#   SonarCloud (dihapus Security Engineer), sehingga Gate 5 tidak lagi
#   memerlukan token atau akun apa pun.
#
# PEMAKAIAN
#   bash scripts/run-gates-local.sh              # gate 1, 2, 3, 5
#   WITH_IMAGE=1 bash scripts/run-gates-local.sh # + gate 4 (build image)
#
# Hasil ditulis ke evidence/ agar bisa dilampirkan sebagai bukti.
# Untuk mengisi folder laporan milik Security Engineer (butir 3 backlog PO pada
# README.md), arahkan REPORTS_DIR ke sana:
#   REPORTS_DIR=reports bash scripts/run-gates-local.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
POLICY_DIR="${REPO_ROOT}/policy"
# EVIDENCE_DIR dipertahankan sebagai nama lama agar pemanggilan yang sudah ada
# tetap jalan; REPORTS_DIR adalah nama yang lebih tepat karena isinya mencakup
# laporan mesin-terbaca (SARIF/JSON), bukan hanya log.
EVIDENCE_DIR="${REPORTS_DIR:-${EVIDENCE_DIR:-${REPO_ROOT}/evidence}}"

COMPOSE_FILE="${REPO_ROOT}/docker-compose.yml"
TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:0.58.0}"
GITLEAKS_IMAGE="${GITLEAKS_IMAGE:-zricethezav/gitleaks:v8.28.0}"
HADOLINT_IMAGE="${HADOLINT_IMAGE:-hadolint/hadolint:2.12.0-debian}"
SEMGREP_IMAGE="${SEMGREP_IMAGE:-semgrep/semgrep:1.179.0}"
# Root aplikasi (backend + frontend), relatif terhadap REPO_ROOT (dipakai Gate 2).
APP_DIR_REL="app"

mkdir -p "${EVIDENCE_DIR}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
REPORT="${EVIDENCE_DIR}/gates-local-${STAMP}.log"

# Path direktori laporan relatif terhadap REPO_ROOT, karena container Gitleaks
# dan Trivy menerima path di dalam mount /repo (atau /src), bukan path host.
EVIDENCE_ABS="$(cd "${EVIDENCE_DIR}" && pwd)"
case "${EVIDENCE_ABS}" in
    "${REPO_ROOT}"/*) EVIDENCE_REL="${EVIDENCE_ABS#"${REPO_ROOT}"/}" ;;
    *)
        echo "PERINGATAN: ${EVIDENCE_ABS} berada di luar ${REPO_ROOT}." >&2
        echo "           SARIF/JSON tidak dapat ditulis dari dalam container." >&2
        EVIDENCE_REL=""
        ;;
esac

FAIL_N=0
run_gate() { # nomor, judul
    echo
    echo "============================================================"
    echo "Gate $1 — $2"
    echo "============================================================"
}

fail() { FAIL_N=$((FAIL_N + 1)); echo "[FAIL] $1"; }
ok()   { echo "[PASS] $1"; }
warn() { echo "[WARN] $1"; }

exec > >(tee -a "${REPORT}") 2>&1

echo "== Security Gate lokal — Axon DSS =="
echo "Repo   : ${REPO_ROOT}"
echo "Waktu  : $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "Laporan: ${REPORT}"

# ---------------------------------------------------------------- Gate 1
run_gate 1 "Secret scan (Gitleaks)"
# Dua keluaran sekaligus: SARIF (mesin-terbaca, dapat diunggah ke tab Security
# GitHub) dan JSON (arsip bukti). Ini memenuhi butir 3 backlog PO pada README.md
# yang meminta laporan berformat SARIF/JSON, bukan sekadar log teks.
GITLEAKS_ARGS=()
if [[ -n "${EVIDENCE_REL}" ]]; then
    GITLEAKS_ARGS+=(--report-format sarif --report-path "/repo/${EVIDENCE_REL}/gitleaks.sarif")
fi
if docker run --rm -v "${REPO_ROOT}:/repo" "${GITLEAKS_IMAGE}" detect \
        --source=/repo \
        --config=/repo/policy/gitleaks.toml \
        --redact --no-banner --exit-code 1 \
        "${GITLEAKS_ARGS[@]+"${GITLEAKS_ARGS[@]}"}"; then
    ok "Tidak ada secret terdeteksi"
else
    fail "Gitleaks menemukan indikasi secret (ZERO TOLERANCE)"
fi

# ---------------------------------------------------------------- Gate 2
run_gate 2 "SCA dependensi + SBOM (Trivy fs)"
if docker run --rm -v "${REPO_ROOT}:/src" -w /src "${TRIVY_IMAGE}" \
        fs --config /src/policy/trivy.yaml \
           /src; then
    ok "Tidak ada CRITICAL pada dependensi"
else
    fail "Trivy fs menemukan CRITICAL (sesuai risk tolerance PO)"
fi

# Laporan mesin-terbaca (butir 3 backlog PO): SARIF untuk tab Security GitHub
# dan JSON sebagai arsip bukti. --exit-code 0 dipakai agar pembuatan laporan
# tidak menggandakan kegagalan yang sudah dilaporkan pemeriksaan di atas.
if [[ -n "${EVIDENCE_REL}" ]]; then
    echo
    echo "-- Laporan SCA (SARIF + JSON) --"
    for spec in "sarif trivy-fs.sarif" "json trivy-fs.json"; do
        read -r fmt out <<<"${spec}"
        if docker run --rm -v "${REPO_ROOT}:/repo" -w /repo "${TRIVY_IMAGE}" \
                fs --scanners vuln,misconfig \
                   --severity CRITICAL,HIGH,MEDIUM --exit-code 0 \
                   --format "${fmt}" \
                   --output "/repo/${EVIDENCE_REL}/${out}" \
                   /repo >/dev/null 2>&1; then
            ok "Laporan ${fmt} dibuat: ${EVIDENCE_REL}/${out}"
        else
            fail "Gagal membuat laporan ${fmt}"
        fi
    done
fi

echo
echo "-- SBOM CycloneDX (Prioritas P1 pada 2.1 Developer Analysis Result) --"
if bash "${SCRIPT_DIR}/generate-sbom.sh"; then
    ok "SBOM backend + frontend dihasilkan"
else
    fail "Pembuatan SBOM gagal"
fi

# ---------------------------------------------------------------- Gate 3
run_gate 3 "Infra policy + Hadolint"
if bash "${POLICY_DIR}/scripts/check-infra-policy.sh" "${COMPOSE_FILE}"; then
    ok "check-infra-policy.sh lolos"
else
    fail "check-infra-policy.sh gagal"
fi

# Pemeriksaan Laravel (T-02 raw query, T-11 SRI) dijalankan dari root aplikasi
# karena skrip Security mencari folder app/ dan routes/ relatif terhadap CWD.
echo
echo "-- check-infra-policy.sh dari root aplikasi (mencakup T-02) --"
if ( cd "${REPO_ROOT}/app/backend" \
     && bash "${POLICY_DIR}/scripts/check-infra-policy.sh" "${COMPOSE_FILE}" ); then
    ok "Pemeriksaan Laravel lolos"
else
    fail "Pemeriksaan Laravel gagal"
fi

echo
echo "-- Hadolint (lint Dockerfile) --"
while IFS= read -r dockerfile; do
    # DL3018 (pin versi paket apk) diabaikan secara sadar: paket alpine mengikuti
    # versi base image, dan memaksa pin per paket membuat image cepat usang
    # sehingga justru menghambat penyerapan patch keamanan.
    if docker run --rm -i "${HADOLINT_IMAGE}" hadolint --ignore DL3018 - < "${dockerfile}"; then
        ok "Hadolint bersih: ${dockerfile#"${REPO_ROOT}"/}"
    else
        fail "Hadolint menemukan masalah: ${dockerfile#"${REPO_ROOT}"/}"
    fi
done < <(find "${REPO_ROOT}/docker" -type f -name 'Dockerfile' | sort)

# ---------------------------------------------------------------- Gate 4
if [[ "${WITH_IMAGE:-0}" == "1" ]]; then
    run_gate 4 "Container image scan (Trivy image)"
    docker compose -f "${COMPOSE_FILE}" build
    for image in axon-dss-app axon-dss-proxy; do
        if docker run --rm -v /var/run/docker.sock:/var/run/docker.sock "${TRIVY_IMAGE}" \
                image --config /dev/null --severity CRITICAL --exit-code 1 "${image}:latest"; then
            ok "Tidak ada CRITICAL pada image ${image}"
        else
            fail "Image ${image} memiliki CRITICAL"
        fi
    done
else
    echo
    echo "[LEWAT] Gate 4 dilewati. Jalankan dengan WITH_IMAGE=1 untuk build + scan image."
fi

# ---------------------------------------------------------------- Gate 5
run_gate 5 "SAST (Semgrep)"
# Non-blocking, sama seperti di pipeline: temuan SAST perlu ditriase lebih dulu.
# Suaranya tetap terlihat lewat [WARN] dan berkas laporan SARIF.
SEMGREP_ARGS=()
if [[ -n "${EVIDENCE_REL}" ]]; then
    SEMGREP_ARGS+=(--output="/src/${EVIDENCE_REL}/semgrep.sarif")
fi
if docker run --rm -v "${REPO_ROOT}:/src" -w /src \
        -e SEMGREP_SEND_METRICS=off \
        "${SEMGREP_IMAGE}" semgrep scan \
        --config=p/php \
        --config=p/javascript \
        --config=p/owasp-top-ten \
        --metrics=off --severity ERROR --sarif --error \
        --exclude=vendor --exclude=node_modules --exclude=coverage \
        "${SEMGREP_ARGS[@]+"${SEMGREP_ARGS[@]}"}" \
        "${APP_DIR_REL}"; then
    ok "Tidak ada temuan SAST"
else
    warn "Semgrep melaporkan temuan SAST — non-blocking, silakan triase laporannya"
fi

# ---------------------------------------------------------------- Ringkasan
echo
echo "============================================================"
echo "Ringkasan: ${FAIL_N} gate GAGAL"
echo "Laporan  : ${REPORT}"
echo "============================================================"
[[ "${FAIL_N}" -eq 0 ]]
