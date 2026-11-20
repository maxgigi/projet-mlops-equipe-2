#!/usr/bin/env bash
# =============================================================================
# scripts/40_load_generator.sh : générateur de charge       [S'EXÉCUTE SUR LAB-LOAD]
#
# Étape 6 du guide. Ce script :
#   1. installe k6 ;
#   2. copie les scripts de benchmark dans ~/p5/bench ;
#   3. écrit ~/p5/bench/target.env (URL de l'API cible) ;
#   4. vérifie que lab-k8s est joignable puis lance un test de fumée de 10 s.
#
# lab-load reste VOLONTAIREMENT hors du cluster (règle du §9 du sujet) :
# kubectl n'y est donc pas installé.
# =============================================================================
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT_DIR}/lib/common.sh"
load_config

BENCH_DIR="${HOME}/p5/bench"
URL="http://${K8S_IP}:${NODE_PORT}/v1/models/${APP_NAME}:predict"
PAYLOAD='{"instances": [[8.3252, 41.0, 6.98, 1.02, 322.0, 2.55, 37.88, -122.23]]}'

# --- 1. Installation de k6 ---------------------------------------------------
step "Installation de k6"
if command -v k6 >/dev/null 2>&1; then
  ok "k6 déjà installé : $(k6 version | head -n1)"
else
  sudo env DEBIAN_FRONTEND=noninteractive apt-get update -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg curl ca-certificates

  # Dépôt officiel k6 : clé GPG puis source apt (procédure de la doc k6).
  sudo gpg -k >/dev/null 2>&1 || true
  sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg \
    --keyserver hkp://keyserver.ubuntu.com:80 \
    --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
  echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" \
    | sudo tee /etc/apt/sources.list.d/k6.list >/dev/null
  sudo env DEBIAN_FRONTEND=noninteractive apt-get update -y
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y k6
  ok "k6 installé : $(k6 version | head -n1)"
fi

# Horloge à l'heure : les horodatages de k6 doivent concorder avec Prometheus.
sudo timedatectl set-ntp true || warn "Impossible d'activer le NTP (non bloquant)."

# --- 2. Scripts de benchmark -------------------------------------------------
step "Installation des scripts dans ${BENCH_DIR}"
mkdir -p "${BENCH_DIR}/k6" "${BENCH_DIR}/results"
cp -r "${ROOT_DIR}/bench/." "${BENCH_DIR}/"
chmod +x "${BENCH_DIR}/run_scenario.sh"
ok "Scripts copiés."

# --- 3. Cible ----------------------------------------------------------------
step "Écriture de ${BENCH_DIR}/target.env"
cat > "${BENCH_DIR}/target.env" <<EOF
# Généré par scripts/40_load_generator.sh
# Usage : source ~/p5/bench/target.env   (définit la variable URL)
export URL="${URL}"
EOF
ok "Cible : ${URL}"

# --- 4. Tests ----------------------------------------------------------------
step "Test de joignabilité de l'API depuis lab-load"
SUCCESS=0
for attempt in $(seq 1 5); do
  RESPONSE="$(curl -s -m 10 -X POST "${URL}" -H 'Content-Type: application/json' -d "${PAYLOAD}" || true)"
  if grep -q '"predictions"' <<<"${RESPONSE}"; then SUCCESS=1; break; fi
  info "Tentative ${attempt}/5 sans réponse, nouvel essai dans 3 s..."
  sleep 3
done
(( SUCCESS == 1 )) || die "lab-load n'atteint pas ${URL} (IP, pare-feu ou appli arrêtée ?)."
ok "Réponse : ${RESPONSE}"

step "Test de fumée k6 (10 s, 2 clients)"
# --vus/--duration remplacent la définition du scénario : simple vérification.
k6 run --vus 2 --duration 10s -e SCENARIO=b1 -e URL="${URL}" "${BENCH_DIR}/k6/load.js" \
  | grep -E "http_reqs|http_req_failed|http_req_duration" || true

step "Étape 40 terminée"
info "Pour lancer un vrai B1 (3 répétitions) :  ~/p5/bench/run_scenario.sh b1"
