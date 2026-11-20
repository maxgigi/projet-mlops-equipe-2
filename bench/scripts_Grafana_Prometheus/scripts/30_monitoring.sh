#!/usr/bin/env bash
# =============================================================================
# scripts/30_monitoring.sh : Prometheus + Grafana (OBS-2)    [S'EXÉCUTE SUR LAB-K8S]
#
# Étape 5 du guide. Ce script :
#   1. crée le namespace de monitoring ;
#   2. crée le Secret « grafana-admin » (mot de passe aléatoire, jamais dans
#      Git : exigence ENG-2) s'il n'existe pas déjà ;
#   3. génère ~/p5/k8s/values-monitoring.yaml ;
#   4. installe (ou met à jour) kube-prometheus-stack avec Helm ;
#   5. lance les port-forward de Grafana et Prometheus en arrière-plan.
# =============================================================================
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT_DIR}/lib/common.sh"
load_config
export KUBECONFIG="${HOME}/.kube/config"

K8S_DIR="${HOME}/p5/k8s"
RELEASE="kps"   # Nom de la release Helm : il préfixe les noms des services créés
                # (ex. svc/kps-grafana). Les autres scripts s'appuient dessus.
mkdir -p "${K8S_DIR}"

# --- 1. Namespace ------------------------------------------------------------
step "Namespace de monitoring : ${MONITORING_NAMESPACE}"
# « dry-run + apply » : crée le namespace, ou ne fait rien s'il existe déjà.
kubectl create namespace "${MONITORING_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

# --- 2. Secret du mot de passe Grafana --------------------------------------
step "Secret grafana-admin"
if kubectl -n "${MONITORING_NAMESPACE}" get secret grafana-admin >/dev/null 2>&1; then
  # On ne régénère JAMAIS un secret existant : Grafana a déjà enregistré
  # l'ancien mot de passe dans sa base, le changer casserait la connexion.
  ok "Le Secret existe déjà : conservé tel quel."
else
  kubectl -n "${MONITORING_NAMESPACE}" create secret generic grafana-admin \
    --from-literal=admin-user=admin \
    --from-literal=admin-password="$(openssl rand -base64 18)"
  ok "Secret créé (mot de passe aléatoire, stocké uniquement dans le cluster)."
fi

# --- 3. Valeurs Helm ---------------------------------------------------------
step "Génération de ${K8S_DIR}/values-monitoring.yaml"
cat > "${K8S_DIR}/values-monitoring.yaml" <<EOF
# Fichier généré par scripts/30_monitoring.sh.
# Configuration allégée de kube-prometheus-stack pour la VM de test.

alertmanager:
  enabled: false            # À activer pour OBS-4 (alertes)

grafana:
  defaultDashboardsTimezone: browser   # affichage à l'heure de ton navigateur
  admin:
    existingSecret: grafana-admin      # mot de passe lu dans le Secret : rien ici
    userKey: admin-user
    passwordKey: admin-password

prometheus:
  prometheusSpec:
    retention: ${PROM_RETENTION}       # durée de conservation des métriques
    resources:
      requests: {cpu: 200m, memory: 512Mi}
      limits:   {memory: 1Gi}

# k3s embarque ces composants dans un seul processus : leurs endpoints séparés
# n'existent pas, les laisser actifs créerait de fausses alertes « down ».
kubeEtcd:              {enabled: false}
kubeScheduler:         {enabled: false}
kubeControllerManager: {enabled: false}
kubeProxy:             {enabled: false}
EOF
ok "Fichier de valeurs généré."

# --- 4. Installation Helm ----------------------------------------------------
step "Installation de kube-prometheus-stack (2 à 5 minutes)"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts >/dev/null 2>&1 || true
helm repo update >/dev/null

# « upgrade --install » : installe la première fois, met à jour ensuite.
# --wait : rend la main quand les pods sont prêts (ou après 10 min).
helm upgrade --install "${RELEASE}" prometheus-community/kube-prometheus-stack \
  -n "${MONITORING_NAMESPACE}" -f "${K8S_DIR}/values-monitoring.yaml" \
  --wait --timeout 10m \
  || die "Installation Helm échouée ou trop lente. Vérifie la mémoire (free -h) et : kubectl -n ${MONITORING_NAMESPACE} get pods"
ok "Prometheus et Grafana installés."

# --- 5. Port-forward en arrière-plan ----------------------------------------
step "Lancement des port-forward (Grafana ${GRAFANA_PORT}, Prometheus ${PROM_PORT})"
# On coupe d'abord d'éventuels anciens port-forward (sinon : "address already in use").
pkill -f "kubectl.*port-forward" || true
sleep 1

# setsid + nohup + redirections : le processus survit à la fin de la session SSH.
# --address 0.0.0.0 : accessible depuis ton hôte, pas seulement depuis la VM.
setsid nohup kubectl -n "${MONITORING_NAMESPACE}" port-forward --address 0.0.0.0 \
  "svc/${RELEASE}-grafana" "${GRAFANA_PORT}:80" \
  > "${HOME}/pf-grafana.log" 2>&1 < /dev/null &

setsid nohup kubectl -n "${MONITORING_NAMESPACE}" port-forward --address 0.0.0.0 \
  "svc/${RELEASE}-kube-prometheus-stack-prometheus" "${PROM_PORT}:9090" \
  > "${HOME}/pf-prometheus.log" 2>&1 < /dev/null &

sleep 3
ok "Port-forward lancés (journaux : ~/pf-grafana.log et ~/pf-prometheus.log)."

step "Étape 30 terminée"
info "Mot de passe Grafana (identifiant : admin) :"
info "  kubectl -n ${MONITORING_NAMESPACE} get secret grafana-admin -o jsonpath='{.data.admin-password}' | base64 -d; echo"
