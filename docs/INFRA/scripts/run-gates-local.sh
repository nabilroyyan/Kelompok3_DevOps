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
#   Gate 3  SCA + SBOM   : Trivy fs (+ SBOM CycloneDX)
#   Gate 4  Infra policy : check-infra-policy.sh milik Security + Hadolint
#   Gate 5  Container    : docker compose build + Trivy image
#
#   Gate 2 (SAST SonarCloud) tidak dijalankan di sini karena memerlukan
#   SONAR_TOKEN dan server SonarCloud; jalankan lewat pipeline.
#
# PEMAKAIAN
#   bash docs/INFRA/scripts/run-gates-local.sh              # gate 1, 3, 4
#   WITH_IMAGE=1 bash docs/INFRA/scripts/run-gates-local.sh # + gate 5 (build image)
#
# Hasil ditulis ke docs/INFRA/evidence/ agar bisa dilampirkan sebagai bukti.
# Untuk mengisi folder laporan milik Security Engineer (butir 3 backlog PO pada
# README.md), arahkan REPORTS_DIR ke sana:
#   REPORTS_DIR=docs/SEC-ENG/reports bash docs/INFRA/scripts/run-gates-local.sh
# =============================================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${INFRA_DIR}/../.." && pwd)"
POLICY_DIR="${REPO_ROOT}/docs/SEC-ENG/policy"
# EVIDENCE_DIR dipertahankan sebagai nama lama agar pemanggilan yang sudah ada
# tetap jalan; REPORTS_DIR adalah nama yang lebih tepat karena isinya mencakup
# laporan mesin-terbaca (SARIF/JSON), bukan hanya log.
EVIDENCE_DIR="${REPORTS_DIR:-${EVIDENCE_DIR:-${INFRA_DIR}/evidence}}"

COMPOSE_FILE="${INFRA_DIR}/docker-compose.yml"
TRIVY_IMAGE="${TRIVY_IMAGE:-aquasec/trivy:0.58.0}"
GITLEAKS_IMAGE="${GITLEAKS_IMAGE:-zricethezav/gitleaks:v8.28.0}"
HADOLINT_IMAGE="${HADOLINT_IMAGE:-hadolint/hadolint:2.12.0-debian}"

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
        --config=/repo/docs/SEC-ENG/policy/gitleaks.toml \
        --redact --no-banner --exit-code 1 \
        "${GITLEAKS_ARGS[@]+"${GITLEAKS_ARGS[@]}"}"; then
    ok "Tidak ada secret terdeteksi"
else
    fail "Gitleaks menemukan indikasi secret (ZERO TOLERANCE)"
fi

# ---------------------------------------------------------------- Gate 3
run_gate 3 "SCA dependensi + SBOM (Trivy fs)"
if docker run --rm -v "${REPO_ROOT}:/src" -w /src "${TRIVY_IMAGE}" \
        fs --config /src/docs/SEC-ENG/policy/trivy.yaml \
           --ignorefile /src/docs/SEC-ENG/policy/.trivyignore \
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
                   --ignorefile "/repo/docs/SEC-ENG/policy/.trivyignore" \
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

# ---------------------------------------------------------------- Gate 4
run_gate 4 "Infra policy + Hadolint"
if bash "${POLICY_DIR}/scripts/check-infra-policy.sh" "${COMPOSE_FILE}"; then
    ok "check-infra-policy.sh lolos"
else
    fail "check-infra-policy.sh gagal"
fi

# Pemeriksaan Laravel (T-02 raw query, T-11 SRI) dijalankan dari root aplikasi
# karena skrip Security mencari folder app/ dan routes/ relatif terhadap CWD.
echo
echo "-- check-infra-policy.sh dari root aplikasi (mencakup T-02) --"
if ( cd "${REPO_ROOT}/docs/Dev/axon-devsecops-dss/app/backend" \
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
done < <(find "${INFRA_DIR}/docker" -type f -name 'Dockerfile' | sort)

# ---------------------------------------------------------------- Gate 5
if [[ "${WITH_IMAGE:-0}" == "1" ]]; then
    run_gate 5 "Container image scan (Trivy image)"
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
    echo "[LEWAT] Gate 5 dilewati. Jalankan dengan WITH_IMAGE=1 untuk build + scan image."
fi

# ---------------------------------------------------------------- Ringkasan
echo
echo "============================================================"
echo "Ringkasan: ${FAIL_N} gate GAGAL"
echo "Laporan  : ${REPORT}"
echo "============================================================"
[[ "${FAIL_N}" -eq 0 ]]
