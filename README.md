# Projet MLOps – Équipe X

## Prérequis
- (poste, accès OpenStack, outils : tofu, ansible, kubectl, helm, python 3.x...)

## Reconstruire de A à Z
make openstack      # 1. déploiement OpenStack
make tenant         # 2. projet/réseaux/VM (OpenTofu)
make cluster        # 3. Kubernetes
make platform       # 4. MinIO, MLflow, Knative, KServe, monitoring
make train          # 5. entraînement
make deploy-model   # 6. déploiement du modèle
make bench          # 7. benchmark
make demo           # 8. démo

## Organisation
Voir docs/architecture.md, docs/adr/ et CONTRIBUTING.md.
