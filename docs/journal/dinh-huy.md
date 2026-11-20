# Journal de Bord - NGUYEN Dinh  Huy (P3 MLflow)

## 21 octobre 2026

### Tâches :
- Lecture du cahier des charges et du planning
- Lecture les documents et instructions d'installation et utilisation de MLflow
- Réunion sur l'analyse de role de MLflow et de jeu des données California Housing dans le projet
- Configuration la machine host local pour installer MLflow

---

## 23 octobre 2026

### Tâches :
- Mise en place de l'environnement Python 3.12 (uv) avec des versions figées (ml/requirements.txt, ml/requirements.lock.txt) : scikit-learn 1.5.1, numpy 1.26.4 et joblib 1.4.2, alignés sur le runtime sklearn de KServe v0.14.0
- Gel du jeu de données California Housing : script ml/src/prepare_data.py et manifeste avec empreinte SHA-256 (le CSV, > 1000 Ko, est régénéré à l'identique et reste hors de Git)
- Lancement d'un serveur MLflow 3.17.2 local de développement

---

## 17 novembre 2026

### Tâches :
- Vérification  le MLflow sur local pour les premiers excutions 
- État des lieux du pôle P3 et plan de travail jusqu'au jalon J4 (27/11) , discussion  répartition avec Khanh (code ML pour Khanh, manifests Kubernetes pour moi)

---

## 18 novembre 2026

### Tâches :
- Passage de l'environnement Python à uv en mode projet (`ml/pyproject.toml`, `ml/uv.lock`, résolution figée au 23/10) ; job CI `uv lock --check`
- Smoke test réécrit pour MLflow 3 (jeu de données figé, vérification de l'alias `champion` et du rechargement)
- ADR-003 et ADR-004 révisés : PostgreSQL 16.15 et RustFS 1.0.6 (version stable) figés, plan B explicite
- Mesure mémoire de la pile P3 : 2,4 Go => 0,7 Go au repos (MLflow à 2 workers, jobs désactivés)

### Difficultés :
- Chargement du modèle bloqué hors du réseau Docker (URL présignées vers `rustfs:9000`) : résolu par `MLFLOW_ENABLE_PROXY_MULTIPART_DOWNLOAD=false`
- MLflow 3.17.2 enregistre les modèles sklearn en `model.skops`, non lu par le runtime sklearn de KServe : à trancher avec P4

---

## 19 novembre 2026

### Tâches:

- Continu de travailler sur les manifests Kubernetes
