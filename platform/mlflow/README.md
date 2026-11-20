# Pile MLflow sur Kubernetes (pôle P3)

PostgreSQL (backend store, ADR-003), RustFS (artefacts S3, ADR-004) et le serveur
MLflow, dans le namespace `mlops`. Versions identiques à `versions.yaml`.

| Composant | Objet | Accès |
|---|---|---|
| PostgreSQL 16.15 | StatefulSet + PVC 2 Gi | `postgres:5432` (interne) |
| RustFS 1.0.6 | StatefulSet + PVC 5 Gi | `http://rustfs.mlops.svc.cluster.local:9000` (S3, utilisé aussi par KServe) |
| Bucket `mlflow` | Job (rc v0.1.37) | — |
| MLflow 3.17.2 | Deployment (2 workers, jobs désactivés) | NodePort **30500** : `http://<IP d'un nœud>:30500` |

Ressources demandées au total : ~0,5 vCPU et ~1 Gio (requests), d'après les mesures
de l'ADR-004. Les volumes utilisent la StorageClass par défaut (local-path, ADR-007).

## Déployer

```bash
# 1. Image du serveur MLflow (pilote PostgreSQL + client S3 figés, non-root)
docker build -t mlops/mlflow-server:3.17.2-2 platform/mlflow/image
#    cluster kind : kind load docker-image mlops/mlflow-server:3.17.2-2 --name p3
#    cluster cible : pousser l'image dans le registre du cluster (à définir avec P2)

# 2. Identifiants (jamais dans Git)
cp platform/mlflow/secret.env.example platform/mlflow/secret.env   # puis éditer

# 3. Déploiement et vérification
kubectl apply -k platform/mlflow
platform/mlflow/check.sh                 # sur la cible : check.sh http://<IP nœud>:30500
```

`check.sh` attend les pods, lance le smoke test de bout en bout via le NodePort,
puis vérifie la persistance (K8S-3) en supprimant le pod PostgreSQL.

## Utiliser depuis un poste hors cluster

```bash
export MLFLOW_TRACKING_URI=http://<IP d'un nœud>:30500
export MLFLOW_ENABLE_PROXY_MULTIPART_DOWNLOAD=false   # obligatoire (ADR-004)
cd ml && uv run python src/hello_run.py
```

Les clients ne parlent qu'au serveur MLflow : aucun identifiant S3 n'est nécessaire
sur le poste. Sur OpenStack, le groupe de sécurité des nœuds doit autoriser le
port TCP 30500 depuis les postes concernés.

## Points d'attention

- `MLFLOW_SERVER_ALLOWED_HOSTS` : par défaut MLflow refuse les en-têtes Host autres
  que localhost et les IP privées, donc le nom du Service (`mlflow.mlops.svc…`)
  utilisé par les autres pods. La liste est étendue dans `mlflow.yaml`.
- Les volumes local-path sont liés à un nœud : si ce nœud est perdu, les données
  le sont aussi (ADR-007). Sauvegarde : `pg_dump` et copie du bucket.
- Le Job `create-bucket` s'efface 10 min après sa fin ; réappliquer la pile le recrée
  (création idempotente).

## Supprimer

```bash
kubectl delete -k platform/mlflow    # les PVC des StatefulSets sont conservés
kubectl -n mlops delete pvc --all    # pour tout effacer
```

## Cluster de développement local (kind)

```bash
kind create cluster --name p3 --config platform/mlflow/kind.yaml
```

Le NodePort 30500 est publié sur `http://localhost:30500`.

**Validation** : sur kind uniquement à ce jour ; à rejouer sur le cluster OpenStack.
