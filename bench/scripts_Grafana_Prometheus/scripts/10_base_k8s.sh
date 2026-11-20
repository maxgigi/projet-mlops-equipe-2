#!/usr/bin/env bash
# =============================================================================
# scripts/10_base_k8s.sh : préparation de lab-k8s            [S'EXÉCUTE SUR LAB-K8S]
#
# Étape 3 du guide. Ce script :
#   1. met le système à jour et active la synchronisation de l'heure (NTP) ;
#   2. installe k3s (Kubernetes léger, metrics-server inclus) ;
#   3. configure kubectl pour l'utilisateur courant ;
#   4. installe Helm (gestionnaire de paquets Kubernetes) ;
#   5. installe Docker (pour construire l'image de l'appli témoin) ;
#   6. attend que le nœud soit Ready et que « kubectl top » fonctionne (OBS-1).
#
# Relançable sans danger : chaque installation est ignorée si déjà faite.
# =============================================================================
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT_DIR}/lib/common.sh"
load_config

# apt en mode totalement non interactif (sinon apt peut poser des questions
# sur les fichiers de configuration ou le redémarrage de services).
apt_get() {
  sudo env DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a \
    apt-get -y -o Dpkg::Options::=--force-confold "$@"
}

# --- 1. Système et horloge ---------------------------------------------------
step "Mise à jour du système"
apt_get update
apt_get upgrade
apt_get install curl ca-certificates openssl

# Une horloge fausse décale les courbes Grafana : on active le NTP.
sudo timedatectl set-ntp true || warn "Impossible d'activer le NTP (non bloquant)."

# --- 2. k3s ------------------------------------------------------------------
step "Installation de k3s"
if command -v k3s >/dev/null 2>&1; then
  ok "k3s est déjà installé : $(k3s --version | head -n1)"
else
  # Si K3S_VERSION est renseignée, on fige la version (exigence H4 du sujet).
  K3S_ENV=()
  [[ -n "${K3S_VERSION}" ]] && K3S_ENV+=("INSTALL_K3S_VERSION=${K3S_VERSION}")
  curl -sfL https://get.k3s.io | sudo env "${K3S_ENV[@]}" sh -
  ok "k3s installé."
fi

# On attend que le nœud soit Ready (peut prendre 30 à 60 s).
wait_until "nœud Kubernetes Ready" 180 \
  sudo k3s kubectl wait --for=condition=Ready node --all --timeout=5s \
  || die "Le nœud k3s n'est pas Ready après 3 minutes (voir : sudo journalctl -u k3s)."
ok "Nœud Ready."

# --- 3. kubectl sans sudo ----------------------------------------------------
step "Configuration de kubectl pour l'utilisateur $(id -un)"
mkdir -p "${HOME}/.kube"
sudo cp /etc/rancher/k3s/k3s.yaml "${HOME}/.kube/config"
sudo chown "$(id -un):$(id -gn)" "${HOME}/.kube/config"
chmod 600 "${HOME}/.kube/config"
# Ajoute l'export dans ~/.bashrc une seule fois (grep -x : ligne exacte).
LINE='export KUBECONFIG=$HOME/.kube/config'
grep -qxF "$LINE" "${HOME}/.bashrc" || echo "$LINE" >> "${HOME}/.bashrc"
export KUBECONFIG="${HOME}/.kube/config"
ok "kubectl configuré."

# --- 4. Helm -----------------------------------------------------------------
step "Installation de Helm"
if command -v helm >/dev/null 2>&1; then
  ok "Helm déjà installé : $(helm version --short)"
else
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  ok "Helm installé : $(helm version --short)"
fi

# --- 5. Docker ---------------------------------------------------------------
step "Installation de Docker"
if command -v docker >/dev/null 2>&1; then
  ok "Docker déjà installé."
else
  apt_get install docker.io
  ok "Docker installé."
fi
sudo systemctl enable --now docker
# Ajoute l'utilisateur au groupe docker (effectif à la prochaine connexion).
# Les scripts suivants utilisent « sudo docker » : pas besoin de se reconnecter.
sudo usermod -aG docker "$(id -un)"

# --- 6. Validation OBS-1 -----------------------------------------------------
step "Validation OBS-1 : metrics-server et kubectl top"
if wait_until "metrics-server prêt" 240 kubectl top nodes; then
  kubectl top nodes
  ok "OBS-1 : « kubectl top » fonctionne."
else
  warn "metrics-server ne répond pas encore. Réessaie « kubectl top nodes » dans 1-2 min."
fi

step "Étape 10 terminée"
kubectl get nodes
