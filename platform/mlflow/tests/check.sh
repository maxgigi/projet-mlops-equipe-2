#!/usr/bin/env bash
# Vérifie la pile MLflow déployée (pôle P3).
#   1. pods prêts ;
#   2. smoke test de bout en bout via le NodePort (run, Registry, alias, rechargement) ;
#   3. persistance (exigence K8S-3) : le pod PostgreSQL est supprimé puis recréé,
#      et le modèle enregistré doit toujours être là.
# Usage (depuis la racine du dépôt) :
#   platform/mlflow/tests/check.sh [URL_MLFLOW]   # défaut : http://localhost:30500
set -euo pipefail

NS=mlops
URL="${1:-http://localhost:30500}"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
export MLFLOW_TRACKING_URI="$URL"
export MLFLOW_ENABLE_PROXY_MULTIPART_DOWNLOAD=false
export MLFLOW_DISABLE_AGENT_HINT=1

echo "== 1. Pods prêts"
kubectl -n "$NS" rollout status statefulset/postgres --timeout=180s
kubectl -n "$NS" rollout status statefulset/rustfs --timeout=180s
kubectl -n "$NS" wait --for=condition=complete job/create-bucket --timeout=180s \
  2>/dev/null || echo "   (job create-bucket déjà terminé et nettoyé)"
kubectl -n "$NS" rollout status deployment/mlflow --timeout=300s

echo "== 2. Smoke test via $URL"
(cd "$ROOT/ml" && uv run --frozen python tests/smoke_test.py)

count_versions() {
  (cd "$ROOT/ml" && uv run --frozen python -c \
    "from mlflow import MlflowClient; \
print(len(MlflowClient().search_model_versions(\"name='housing-smoke'\")))")
}

echo "== 3. Persistance (K8S-3)"
before=$(count_versions)
echo "   versions de housing-smoke avant : $before"
kubectl -n "$NS" delete pod postgres-0 --wait=true
kubectl -n "$NS" rollout status statefulset/postgres --timeout=180s
# Le pool de connexions de MLflow se reconnecte à la requête suivante.
for _ in $(seq 1 30); do
  after=$(count_versions 2>/dev/null) && break
  sleep 2
done
echo "   versions de housing-smoke après : ${after:-?}"
if [ "${after:-0}" -ge "$before" ] && [ "$before" -ge 1 ]; then
  echo "OK : données conservées après redémarrage de PostgreSQL"
else
  echo "ÉCHEC : données perdues ou serveur injoignable" >&2
  exit 1
fi
