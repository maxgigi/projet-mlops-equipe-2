#!/usr/bin/env bash
# =============================================================================
# scripts/50_verify.sh : vérifie la chaîne de mesure         [S'EXÉCUTE SUR LAB-K8S]
#
# Teste chaque maillon de : Pod -> cAdvisor/kubelet -> Prometheus -> Grafana
#   1. les pods de monitoring et de l'appli sont-ils prêts ?
#   2. Prometheus répond-il ?
#   3. Prometheus a-t-il des métriques CPU pour le namespace de l'appli ?
#   4. kube-state-metrics fournit-il le nombre de réplicas ?
#   5. Grafana répond-il ?
#
# Ce script ne génère pas de charge : pour voir bouger les courbes, lance
# ~/p5/bench/run_scenario.sh sur lab-load (ou le test de 5 min du guide).
# =============================================================================
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT_DIR}/lib/common.sh"
load_config
export KUBECONFIG="${HOME}/.kube/config"

PROM_URL="http://localhost:${PROM_PORT}"
FAILURES=0   # compteur de vérifications échouées

# prom_count "<requête PromQL>" : affiche le nombre de séries renvoyées par
# Prometheus pour la requête (0 si aucune ou si Prometheus est injoignable).
prom_count() {
  curl -s -m 10 --data-urlencode "query=$1" "${PROM_URL}/api/v1/query" 2>/dev/null \
    | python3 -c '
import json, sys
try:
    print(len(json.load(sys.stdin)["data"]["result"]))
except Exception:
    print(0)
'
}

# check "description" commande... : exécute la commande et affiche OK / ÉCHEC.
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    ok "${desc}"
  else
    warn "ÉCHEC : ${desc}"
    FAILURES=$(( FAILURES + 1 ))
  fi
}

# series_exist "<requête>" : réussit si la requête renvoie au moins une série.
series_exist() { [[ "$(prom_count "$1")" -gt 0 ]]; }

step "1. Pods prêts"
check "Pods de monitoring (${MONITORING_NAMESPACE}) prêts" \
  kubectl -n "${MONITORING_NAMESPACE}" wait --for=condition=Ready pod \
    --all --timeout=120s
check "Pod de l'appli (${APP_NAMESPACE}) prêt" \
  kubectl -n "${APP_NAMESPACE}" wait --for=condition=Ready pod \
    -l "app=${APP_NAME}" --timeout=60s

step "2. Prometheus répond"
check "API Prometheus sur ${PROM_URL}" curl -sf -m 10 "${PROM_URL}/-/ready"

step "3. Métriques CPU du namespace ${APP_NAMESPACE}"
# Prometheus collecte toutes les ~30 s : on laisse jusqu'à 3 minutes.
QUERY_CPU="container_cpu_usage_seconds_total{namespace=\"${APP_NAMESPACE}\",container!=\"\"}"
check "Séries CPU présentes dans Prometheus" \
  wait_until "premières métriques CPU" 180 series_exist "${QUERY_CPU}"

step "4. Nombre de réplicas (kube-state-metrics)"
QUERY_REP="kube_deployment_status_replicas{namespace=\"${APP_NAMESPACE}\"}"
check "Série « réplicas » présente dans Prometheus" \
  wait_until "métriques de réplicas" 180 series_exist "${QUERY_REP}"

step "5. Grafana répond"
check "Grafana sur le port ${GRAFANA_PORT}" curl -sf -m 10 "http://localhost:${GRAFANA_PORT}/api/health"

step "Bilan"
if (( FAILURES == 0 )); then
  ok "Toute la chaîne de mesure fonctionne."
else
  warn "${FAILURES} vérification(s) en échec : voir le guide, section « Vérifier que les données arrivent »."
  exit 1
fi
