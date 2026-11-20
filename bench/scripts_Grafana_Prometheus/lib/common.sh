#!/usr/bin/env bash
# =============================================================================
# lib/common.sh : fonctions partagées par tous les scripts du projet P5.
#
# Ce fichier est « sourcé » (source lib/common.sh), il ne s'exécute pas seul.
# Le script qui le source doit AVANT définir la variable ROOT_DIR : le dossier
# racine du projet (celui qui contient install.sh, lib/, scripts/...).
# =============================================================================

# --- Couleurs (uniquement si la sortie est un vrai terminal) -----------------
if [[ -t 1 ]]; then
  C_BLUE=$'\033[1;34m'; C_GREEN=$'\033[1;32m'
  C_YELLOW=$'\033[1;33m'; C_RED=$'\033[1;31m'; C_RESET=$'\033[0m'
else
  C_BLUE=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_RESET=""
fi

# --- Messages ----------------------------------------------------------------
step() { printf '\n%s==> %s%s\n' "$C_BLUE" "$*" "$C_RESET"; }   # titre d'étape
info() { printf '    %s\n' "$*"; }                              # information
ok()   { printf '    %s[OK]%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
warn() { printf '    %s[ATTENTION]%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
die()  { printf '%s[ERREUR]%s %s\n' "$C_RED" "$C_RESET" "$*" >&2; exit 1; }

# --- Chargement de la configuration -----------------------------------------
# config.env est généré par install.sh et copié sur chaque VM : il contient
# toutes les valeurs choisies (namespaces, ports, versions...). Aucun secret.
load_config() {
  local file="${ROOT_DIR}/config.env"
  [[ -f "$file" ]] || die "Fichier de configuration introuvable : $file"
  # shellcheck disable=SC1090
  source "$file"
}

# --- Question avec valeur par défaut ----------------------------------------
# Usage : ask VARIABLE "Question" "valeur_par_défaut" ["regex"] ["message d'erreur"]
#
#  - Si l'utilisateur appuie sur Entrée sans rien taper : la valeur par défaut
#    est utilisée.
#  - Si la variable existe déjà (ex. chargée depuis un config.env précédent),
#    sa valeur devient le nouveau défaut proposé.
#  - Si ASSUME_DEFAULTS=1 (option --defaults) : aucune question n'est posée.
#  - Si une regex est fournie, la réponse doit la respecter, sinon on redemande.
ask() {
  local var="$1" question="$2" default="$3" regex="${4:-}"
  local errmsg="${5:-Valeur invalide, réessaie.}"
  local current="${!var:-$default}" answer

  while true; do
    if [[ "${ASSUME_DEFAULTS:-0}" == "1" ]]; then
      answer="$current"
    else
      read -r -p "  ${question} [${current:-vide}] : " answer || answer=""
      answer="${answer:-$current}"
    fi

    if [[ -z "$regex" || "$answer" =~ $regex ]]; then
      break
    fi
    [[ "${ASSUME_DEFAULTS:-0}" == "1" ]] && die "Valeur par défaut invalide pour ${var} : '${answer}'"
    warn "$errmsg"
  done

  printf -v "$var" '%s' "$answer"   # affecte la réponse à la variable nommée
}

# --- Attente active ----------------------------------------------------------
# Usage : wait_until "description" délai_max_en_secondes commande [args...]
# Relance la commande toutes les 5 s jusqu'à ce qu'elle réussisse.
# Retourne 0 en cas de succès, 1 si le délai est dépassé.
wait_until() {
  local desc="$1" timeout="$2"; shift 2
  local elapsed=0
  info "Attente : ${desc} (max ${timeout}s)..."
  until "$@" >/dev/null 2>&1; do
    if (( elapsed >= timeout )); then
      return 1
    fi
    sleep 5
    elapsed=$(( elapsed + 5 ))
  done
  return 0
}
