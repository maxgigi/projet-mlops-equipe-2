#!/usr/bin/env bash
# =============================================================================
# bench/run_scenario.sh : lance un scénario k6 avec N répétitions
#                                                            [S'EXÉCUTE SUR LAB-LOAD]
#
# Usage : ./run_scenario.sh <b1|b2|b5> [répétitions=3] [pause_en_secondes=60]
#
# Le protocole (§9 du sujet) exige au moins 3 répétitions par scénario, avec un
# retour au repos entre deux répétitions. Chaque répétition produit un fichier
# JSON de synthèse dans results/ (à versionner dans Git).
#
# Exemple : ./run_scenario.sh b1          # 3 répétitions de B1, pause de 60 s
#           ./run_scenario.sh b2 3 120    # 3 répétitions de B2, pause de 120 s
# =============================================================================
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCENARIO="${1:-}"
REPS="${2:-3}"
PAUSE="${3:-60}"

case "${SCENARIO}" in
  b1|b2|b5) ;;
  *) echo "Usage : $0 <b1|b2|b5> [répétitions=3] [pause_s=60]" >&2; exit 1 ;;
esac

# target.env (généré à l'installation) définit la variable URL de l'API cible.
# shellcheck disable=SC1091
source "${BENCH_DIR}/target.env"
mkdir -p "${BENCH_DIR}/results"

STAMP="$(date +%Y%m%d-%H%M%S)"   # évite d'écraser les résultats d'une campagne précédente
LABEL="$(echo "${SCENARIO}" | tr '[:lower:]' '[:upper:]')"

echo "Scénario ${LABEL} : ${REPS} répétition(s), cible ${URL}"
for run in $(seq 1 "${REPS}"); do
  echo "--- Répétition ${run}/${REPS} ---"
  k6 run -e SCENARIO="${SCENARIO}" -e URL="${URL}" \
    --summary-export="${BENCH_DIR}/results/${LABEL}-${STAMP}-run${run}.json" \
    "${BENCH_DIR}/k6/load.js"

  if (( run < REPS )); then
    echo "Pause de ${PAUSE} s (retour au repos du système)..."
    sleep "${PAUSE}"
  fi
done
echo "Terminé. Résultats dans ${BENCH_DIR}/results/"
