#!/usr/bin/env bash
# =============================================================================
# install.sh : script principal du lab P5                   [S'EXÉCUTE SUR L'HÔTE]
#
# Il automatise tout le « Guide pas à pas : ta machine de test P5 » :
#   1. pose les questions de configuration (Entrée = valeur par défaut) ;
#   2. vérifie la connexion SSH vers lab-k8s et lab-load ;
#   3. copie ce dossier sur les deux VM ;
#   4. appelle les scripts d'étape, dans l'ordre :
#        base       -> scripts/10_base_k8s.sh        (lab-k8s)  k3s, Helm, Docker
#        app        -> scripts/20_deploy_app.sh      (lab-k8s)  appli témoin
#        monitoring -> scripts/30_monitoring.sh      (lab-k8s)  Prometheus, Grafana
#        load       -> scripts/40_load_generator.sh  (lab-load) k6
#        verify     -> scripts/50_verify.sh          (lab-k8s)  contrôle de la chaîne
#
# Prérequis : les deux VM existent, sont démarrées, et tu peux t'y connecter en
# SSH par clé depuis cette machine.
#
# Usage :
#   ./install.sh                       # interactif, tout installer
#   ./install.sh --defaults            # aucune question, valeurs par défaut
#   ./install.sh --only app,monitoring # ne relancer que certaines étapes
#   ./install.sh --help
# =============================================================================
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "${ROOT_DIR}/lib/common.sh"

ASSUME_DEFAULTS=0
ALL_STEPS="base app monitoring load verify"
STEPS="${ALL_STEPS}"

usage() {
  cat <<'EOF'
Usage : ./install.sh [options]

  (aucune option)      mode interactif, installe tout
  -y, --defaults       aucune question, valeurs par défaut (ou config.env existant)
  --only étape,étape   ne lance que certaines étapes parmi :
                       base, app, monitoring, load, verify
  -h, --help           affiche cette aide

Exemples :
  ./install.sh
  ./install.sh --defaults
  ./install.sh --only app,monitoring
EOF
}

# --- Lecture des options -----------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--defaults) ASSUME_DEFAULTS=1; shift ;;
    --only)
      [[ $# -ge 2 ]] || die "--only attend une liste (ex. --only app,monitoring)"
      STEPS="${2//,/ }"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die "Option inconnue : $1 (voir --help)" ;;
  esac
done
for s in ${STEPS}; do
  [[ " ${ALL_STEPS} " == *" ${s} "* ]] || die "Étape inconnue : '${s}'. Valeurs possibles : ${ALL_STEPS}"
done
should_run() { [[ " ${STEPS} " == *" $1 "* ]]; }

# Si une configuration précédente existe, ses valeurs deviennent les défauts.
if [[ -f "${ROOT_DIR}/config.env" ]]; then
  # shellcheck disable=SC1091
  source "${ROOT_DIR}/config.env"
  info "Configuration précédente trouvée : ses valeurs sont proposées par défaut."
fi

# --- Expressions de validation des réponses ---------------------------------
RE_DNS='^[a-z0-9]([-a-z0-9]*[a-z0-9])?$'                    # nom Kubernetes valide
RE_IP='^([0-9]{1,3}\.){3}[0-9]{1,3}$'
RE_USER='^[a-z_][a-z0-9_-]*$'
RE_NODEPORT='^(3[01][0-9]{3}|32[0-6][0-9]{2}|327[0-5][0-9]|3276[0-7])$'   # 30000-32767
RE_PORT='^[0-9]{2,5}$'
RE_INT='^[0-9]+$'
RE_CPU='^([0-9]+m|[0-9]+(\.[0-9]+)?)$'                       # 250m, 1, 0.5
RE_MEM='^[0-9]+(Mi|Gi)$'                                      # 256Mi, 1Gi
RE_TAG='^[A-Za-z0-9_.-]+$'
RE_K3S='^(v[0-9]+\.[0-9]+\.[0-9]+\+k3s[0-9]+)?$'             # vide ou v1.30.5+k3s1
RE_RETENTION='^[0-9]+[smhdwy]$'                               # 2d, 12h...

# Variables enregistrées dans config.env (aucune ne contient de secret).
CONFIG_VARS=(SSH_USER SSH_KEY K8S_IP LOAD_IP APP_NAMESPACE MONITORING_NAMESPACE
  APP_NAME IMAGE_TAG NODE_PORT K3S_VERSION CPU_REQUEST CPU_LIMIT MEM_REQUEST
  MEM_LIMIT HPA_MIN HPA_MAX HPA_CPU_TARGET PROM_RETENTION GRAFANA_PORT PROM_PORT)

# --- 1. Questions ------------------------------------------------------------
collect_config() {
  step "Configuration (Entrée = valeur par défaut entre crochets)"

  echo; info "-- Connexion aux machines --"
  ask SSH_USER "Utilisateur SSH des VM" "ubuntu" "${RE_USER}"
  ask SSH_KEY  "Clé privée SSH (vide = clés par défaut)" "~/.ssh/key/id_ed25519"
  ask K8S_IP   "IP de lab-k8s (cluster)" "192.168.122.50" "${RE_IP}" "Adresse IPv4 attendue."
  ask LOAD_IP  "IP de lab-load (générateur de charge)" "192.168.122.51" "${RE_IP}" "Adresse IPv4 attendue."

  echo; info "-- Noms Kubernetes --"
  ask APP_NAMESPACE        "Namespace de l'appli" "models" "${RE_DNS}" \
    "Minuscules, chiffres et tirets uniquement (ex. models)."
  ask MONITORING_NAMESPACE "Namespace du monitoring" "monitoring" "${RE_DNS}" \
    "Minuscules, chiffres et tirets uniquement (ex. monitoring)."
  ask APP_NAME             "Nom de l'appli / du modèle" "housing-sklearn" "${RE_DNS}" \
    "Minuscules, chiffres et tirets uniquement."
  ask NODE_PORT            "Port d'accès à l'appli (NodePort 30000-32767)" "30080" "${RE_NODEPORT}" \
    "Un NodePort doit être compris entre 30000 et 32767."

  # Valeurs par défaut des réglages avancés (utilisées si on ne les modifie pas).
  : "${IMAGE_TAG:=0.1}" "${K3S_VERSION:=}" "${CPU_REQUEST:=250m}" "${CPU_LIMIT:=1}"
  : "${MEM_REQUEST:=256Mi}" "${MEM_LIMIT:=512Mi}" "${HPA_MIN:=1}" "${HPA_MAX:=5}"
  : "${HPA_CPU_TARGET:=50}" "${PROM_RETENTION:=2d}" "${GRAFANA_PORT:=3000}" "${PROM_PORT:=9090}"

  local advanced="n"
  if [[ "${ASSUME_DEFAULTS}" != "1" ]]; then
    echo
    read -r -p "  Modifier les réglages avancés (version k3s, ressources, HPA, ports) ? [o/N] : " advanced || advanced="n"
  fi
  if [[ "${advanced}" =~ ^[oOyY]$ ]]; then
    echo; info "-- Réglages avancés --"
    ask K3S_VERSION     "Version de k3s (vide = dernière ; ex. v1.30.5+k3s1)" "${K3S_VERSION}" "${RE_K3S}"
    ask IMAGE_TAG       "Tag de l'image Docker" "${IMAGE_TAG}" "${RE_TAG}"
    ask CPU_REQUEST     "CPU demandé (request)" "${CPU_REQUEST}" "${RE_CPU}"
    ask CPU_LIMIT       "CPU maximum (limit)" "${CPU_LIMIT}" "${RE_CPU}"
    ask MEM_REQUEST     "Mémoire demandée (request)" "${MEM_REQUEST}" "${RE_MEM}"
    ask MEM_LIMIT       "Mémoire maximum (limit)" "${MEM_LIMIT}" "${RE_MEM}"
    ask HPA_MIN         "HPA : réplicas minimum" "${HPA_MIN}" "${RE_INT}"
    ask HPA_MAX         "HPA : réplicas maximum" "${HPA_MAX}" "${RE_INT}"
    ask HPA_CPU_TARGET  "HPA : cible CPU (% de la request)" "${HPA_CPU_TARGET}" "${RE_INT}"
    ask PROM_RETENTION  "Rétention Prometheus (ex. 2d, 12h)" "${PROM_RETENTION}" "${RE_RETENTION}"
    ask GRAFANA_PORT    "Port Grafana sur la VM" "${GRAFANA_PORT}" "${RE_PORT}"
    ask PROM_PORT       "Port Prometheus sur la VM" "${PROM_PORT}" "${RE_PORT}"
  fi
}

# --- 2. Enregistrement de la configuration -----------------------------------
write_config() {
  {
    echo "# Généré par install.sh : ne contient aucun secret."
    local v
    for v in "${CONFIG_VARS[@]}"; do
      printf '%s=%q\n' "${v}" "${!v}"   # %q protège espaces et caractères spéciaux
    done
  } > "${ROOT_DIR}/config.env"
  chmod 600 "${ROOT_DIR}/config.env"
}

show_summary() {
  step "Récapitulatif"
  local v
  for v in "${CONFIG_VARS[@]}"; do
    printf '    %-22s %s\n' "${v}" "${!v:-<vide>}"
  done
  echo "    Étapes à exécuter      : ${STEPS}"
  if [[ "${ASSUME_DEFAULTS}" != "1" ]]; then
    local go
    read -r -p $'\n  Lancer l\'installation ? [O/n] : ' go || go="n"
    [[ "${go:-O}" =~ ^[oOyY]?$ ]] || die "Abandon à ta demande (config.env conservé)."
  fi
}

# --- 3. SSH ------------------------------------------------------------------
build_ssh_opts() {
  SSH_OPTS=(-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10
            -o ServerAliveInterval=30)
  local key="${SSH_KEY/#\~/$HOME}"           # remplace un ~ initial par $HOME
  if [[ -n "${key}" ]]; then
    if [[ -f "${key}" ]]; then
      SSH_OPTS+=(-i "${key}" -o IdentitiesOnly=yes)   # n'essaie QUE cette clé
    else
      warn "Clé SSH introuvable (${key}) : les clés par défaut seront utilisées."
    fi
  fi
}

# check_ssh <user@ip> : joignable en SSH par clé, et sudo sans mot de passe ?
check_ssh() {
  local target="$1"
  ssh "${SSH_OPTS[@]}" -o BatchMode=yes "${target}" true 2>/dev/null \
    || die "Connexion SSH impossible vers ${target}. Teste : ssh -i <clé> ${target}"
  ssh "${SSH_OPTS[@]}" "${target}" 'sudo -n true' 2>/dev/null \
    || die "${target} : sudo demande un mot de passe (les scripts en ont besoin sans)."
  ok "SSH et sudo fonctionnent sur ${target}"
}

# push_files <user@ip> : copie ce dossier dans ~/p5-lab sur la VM (tar via SSH,
# sans dépendre de rsync).
push_files() {
  local target="$1"
  tar -C "${ROOT_DIR}" --exclude='.git' -cf - . \
    | ssh "${SSH_OPTS[@]}" "${target}" 'mkdir -p ~/p5-lab && tar -C ~/p5-lab -xf -'
  ok "Fichiers copiés sur ${target}:~/p5-lab"
}

# run_remote <user@ip> <script> : exécute un script d'étape sur la VM.
run_remote() {
  local target="$1" script="$2"
  step ">>> ${script} sur ${target}"
  ssh "${SSH_OPTS[@]}" "${target}" "cd ~/p5-lab && bash scripts/${script}" \
    || die "L'étape ${script} a échoué sur ${target} (voir les messages ci-dessus)."
}

# --- Déroulement -------------------------------------------------------------
collect_config
write_config
show_summary
write_config   # réécrit au cas où le récapitulatif a été validé tel quel

K8S_TARGET="${SSH_USER}@${K8S_IP}"
LOAD_TARGET="${SSH_USER}@${LOAD_IP}"
build_ssh_opts

step "Vérification des connexions"
check_ssh "${K8S_TARGET}"
check_ssh "${LOAD_TARGET}"

step "Envoi des scripts sur les VM"
push_files "${K8S_TARGET}"
push_files "${LOAD_TARGET}"

should_run base       && run_remote "${K8S_TARGET}"  "10_base_k8s.sh"
should_run app        && run_remote "${K8S_TARGET}"  "20_deploy_app.sh"
should_run monitoring && run_remote "${K8S_TARGET}"  "30_monitoring.sh"
should_run load       && run_remote "${LOAD_TARGET}" "40_load_generator.sh"
should_run verify     && run_remote "${K8S_TARGET}"  "50_verify.sh"

# --- Fin ---------------------------------------------------------------------
step "Installation terminée"
cat <<EOF

  Grafana     : http://${K8S_IP}:${GRAFANA_PORT}   (identifiant : admin)
  Prometheus  : http://${K8S_IP}:${PROM_PORT}/targets

  Mot de passe Grafana (à lancer sur lab-k8s) :
    kubectl -n ${MONITORING_NAMESPACE} get secret grafana-admin \\
      -o jsonpath='{.data.admin-password}' | base64 -d; echo

  Lancer un benchmark (sur lab-load) :
    ~/p5/bench/run_scenario.sh b1

  Observer en direct (sur lab-k8s) :
    watch -n 2 'kubectl -n ${APP_NAMESPACE} top pods; echo; kubectl -n ${APP_NAMESPACE} get hpa'

EOF
