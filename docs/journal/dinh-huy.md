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
