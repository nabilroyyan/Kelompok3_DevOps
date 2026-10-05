#!/usr/bin/env bash
# Membuat Quality Gate "Axon-DSS-Baseline" di SonarQube lewat Web API.
# Pemakaian:
#   SONAR_HOST_URL=https://sonar.example.com SONAR_TOKEN=xxxx ./setup-quality-gate.sh
# Token harus milik admin (izin "Administer Quality Gates"). Jalankan sekali saja.
set -euo pipefail

: "${SONAR_HOST_URL:?SONAR_HOST_URL wajib diisi}"
: "${SONAR_TOKEN:?SONAR_TOKEN wajib diisi}"
GATE="Axon-DSS-Baseline"
PROJECT_KEY="${PROJECT_KEY:-axon-dss-dashboard}"

api() { curl -sS -f -u "${SONAR_TOKEN}:" -X POST "$SONAR_HOST_URL/api/$1" "${@:2}"; }

echo ">> Membuat gate $GATE"
api qualitygates/create --data-urlencode "name=$GATE" || echo "(gate mungkin sudah ada, lanjut)"

# metric | operator | nilai error  (GT = gagal jika lebih besar, LT = gagal jika lebih kecil)
# Rating: 1=A, 2=B, ... sehingga "GT 1" berarti gagal jika lebih buruk dari A.
CONDITIONS=(
  "new_security_rating|GT|1"                 # T-02, T-06: nol vulnerability baru
  "new_reliability_rating|GT|1"              # nol bug baru
  "new_maintainability_rating|GT|1"          # technical debt baru terkendali
  "new_security_hotspots_reviewed|LT|100"    # semua hotspot (mis. SQL, kredensial) wajib direview
  "new_coverage|LT|70"                       # cakupan tes kode baru minimal 70%
  "new_duplicated_lines_density|GT|3"        # duplikasi kode baru maksimal 3%
)

for c in "${CONDITIONS[@]}"; do
  IFS='|' read -r metric op error <<<"$c"
  echo ">> Kondisi: $metric $op $error"
  api qualitygates/create_condition \
    --data-urlencode "gateName=$GATE" \
    --data-urlencode "metric=$metric" \
    --data-urlencode "op=$op" \
    --data-urlencode "error=$error" >/dev/null
done

echo ">> Mengaitkan gate ke project $PROJECT_KEY"
api qualitygates/select \
  --data-urlencode "gateName=$GATE" \
  --data-urlencode "projectKey=$PROJECT_KEY" >/dev/null || \
  echo "(project belum ada; kaitkan setelah analisis pertama)"

echo "Selesai."
