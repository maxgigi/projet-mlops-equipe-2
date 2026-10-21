# Pôle P4 - Serving (KServe)

## Validation locale (kind) en mode RawDeployment

### 1. Prérequis
- Cluster Kubernetes local (`kind` ou `k3d`)
- `cert-manager` v1.16.2

### 2. Déploiement de KServe
```bash
# cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.2/cert-manager.yaml

# KServe v0.14.0 (Server-side apply pour éviter les limites de taille d'annotations)
kubectl apply --server-side --force-conflicts -f https://github.com/kserve/kserve/releases/download/v0.14.0/kserve.yaml
kubectl apply --server-side --force-conflicts -f https://github.com/kserve/kserve/releases/download/v0.14.0/kserve-cluster-resources.yaml

# Configuration en mode RawDeployment (sans Knative)
kubectl patch configmap inferenceservice-config -n kserve --type merge -p '{"data": {"deploy": "{\"defaultDeploymentMode\": \"RawDeployment\"}"}}'
```

### 3. Test du modèle test (sklearn)
```bash
kubectl apply -f test-iris.yaml
kubectl port-forward svc/sklearn-iris-predictor 8080:80
curl -s -X POST http://localhost:8080/v1/models/sklearn-iris:predict \
  -H "Content-Type: application/json" \
  -d @predict-iris.json
```
