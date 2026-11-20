#!/usr/bin/env bash
# =============================================================================
# scripts/20_deploy_app.sh : appli témoin                    [S'EXÉCUTE SUR LAB-K8S]
#
# Étape 4 du guide. Ce script :
#   1. copie le code de l'appli dans ~/p5/app ;
#   2. construit l'image Docker (le modèle est entraîné pendant le build) ;
#   3. importe l'image dans containerd (k3s n'utilise pas Docker) ;
#   4. génère ~/p5/k8s/app.yaml (Namespace, Deployment, Service, HPA) ;
#   5. applique le manifeste et teste l'API d'inférence.
#
# Remarque : si tu relances avec le MÊME tag d'image après avoir modifié le
# code, change IMAGE_TAG (ex. 0.2), sinon le pod existant garde l'ancienne image.
# =============================================================================
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../lib/common.sh
source "${ROOT_DIR}/lib/common.sh"
load_config
export KUBECONFIG="${HOME}/.kube/config"

APP_DIR="${HOME}/p5/app"
K8S_DIR="${HOME}/p5/k8s"
IMAGE="${APP_NAME}:${IMAGE_TAG}"

# --- 1. Code de l'appli ------------------------------------------------------
step "Copie du code de l'appli dans ${APP_DIR}"
mkdir -p "${APP_DIR}" "${K8S_DIR}"
cp -r "${ROOT_DIR}/app/." "${APP_DIR}/"
ok "Fichiers copiés."

# --- 2. Construction de l'image ---------------------------------------------
step "Construction de l'image Docker ${IMAGE}"
# « sudo docker » : évite de devoir se reconnecter pour le groupe docker.
sudo docker build -t "${IMAGE}" "${APP_DIR}"

# --- 3. Import dans k3s ------------------------------------------------------
step "Import de l'image dans containerd (k3s)"
sudo docker save "${IMAGE}" | sudo k3s ctr images import -
ok "Image disponible pour Kubernetes."

# --- 4. Manifeste Kubernetes -------------------------------------------------
step "Génération du manifeste ${K8S_DIR}/app.yaml"
# Heredoc SANS guillemets autour de EOF : les ${VARIABLES} sont remplacées
# par les valeurs de config.env.
cat > "${K8S_DIR}/app.yaml" <<EOF
# Fichier généré par scripts/20_deploy_app.sh : ne pas éditer à la main,
# modifier config.env puis relancer install.sh.

# Namespace dédié (K8S-2) : regroupe et isole les objets de l'appli
apiVersion: v1
kind: Namespace
metadata:
  name: ${APP_NAMESPACE}
---
# Deployment : fait tourner le pod, avec requests/limits
# (nécessaires pour B3 et pour que le HPA calcule un pourcentage)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${APP_NAME}
  namespace: ${APP_NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels: {app: ${APP_NAME}}
  template:
    metadata:
      labels: {app: ${APP_NAME}}
    spec:
      containers:
        - name: server
          image: ${IMAGE}
          imagePullPolicy: Never          # image importée localement, pas de registre
          env:
            - name: MODEL_NAME             # définit la route /v1/models/<nom>:predict
              value: "${APP_NAME}"
          ports:
            - containerPort: 8080
          resources:
            requests: {cpu: "${CPU_REQUEST}", memory: "${MEM_REQUEST}"}
            limits:   {cpu: "${CPU_LIMIT}",   memory: "${MEM_LIMIT}"}
          readinessProbe:                  # trafic envoyé seulement si l'appli répond
            httpGet: {path: /healthz, port: 8080}
            initialDelaySeconds: 3
---
# Service NodePort : rend l'appli joignable depuis lab-load
apiVersion: v1
kind: Service
metadata:
  name: ${APP_NAME}
  namespace: ${APP_NAMESPACE}
spec:
  type: NodePort
  selector: {app: ${APP_NAME}}
  ports:
    - port: 80
      targetPort: 8080
      nodePort: ${NODE_PORT}
---
# HPA : ajoute des réplicas quand le CPU moyen dépasse ${HPA_CPU_TARGET} % de la request
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ${APP_NAME}
  namespace: ${APP_NAMESPACE}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ${APP_NAME}
  minReplicas: ${HPA_MIN}
  maxReplicas: ${HPA_MAX}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target: {type: Utilization, averageUtilization: ${HPA_CPU_TARGET}}
EOF
ok "Manifeste généré."

# --- 5. Déploiement et test --------------------------------------------------
step "Déploiement dans le namespace ${APP_NAMESPACE}"
kubectl apply -f "${K8S_DIR}/app.yaml"
kubectl -n "${APP_NAMESPACE}" rollout status "deploy/${APP_NAME}" --timeout=240s \
  || die "Le pod n'est pas prêt (voir : kubectl -n ${APP_NAMESPACE} describe pod)."

step "Test d'inférence (requête de l'Annexe B du sujet)"
URL_LOCAL="http://localhost:${NODE_PORT}/v1/models/${APP_NAME}:predict"
PAYLOAD='{"instances": [[8.3252, 41.0, 6.98, 1.02, 322.0, 2.55, 37.88, -122.23]]}'
SUCCESS=0
for attempt in $(seq 1 10); do
  RESPONSE="$(curl -s -m 10 -X POST "${URL_LOCAL}" \
    -H 'Content-Type: application/json' -d "${PAYLOAD}" || true)"
  if grep -q '"predictions"' <<<"${RESPONSE}"; then
    SUCCESS=1; break
  fi
  info "Tentative ${attempt}/10 sans réponse valide, nouvel essai dans 3 s..."
  sleep 3
done
(( SUCCESS == 1 )) || die "L'API ne répond pas correctement. Dernière réponse : ${RESPONSE:-<vide>}"
ok "Réponse : ${RESPONSE}"

step "Étape 20 terminée"
kubectl -n "${APP_NAMESPACE}" get pods,svc,hpa
info "Le HPA peut afficher <unknown>/${HPA_CPU_TARGET}% pendant ~1 minute : c'est normal."
