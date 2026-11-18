# Tester MLflow avec Docker Compose

Depuis ce dossier (`ml/`), préparer la configuration puis démarrer la stack :

```bash
cp .env.example .env
docker compose -f compose.yaml up -d
docker compose -f compose.yaml ps
```

Ouvrir ensuite l’interface MLflow à l’adresse <http://localhost:5000>. Les
services PostgreSQL, RustFS et MLflow doivent être indiqués comme `healthy` ou
`running`. La console RustFS est disponible sur <http://localhost:9001> pour
vérifier le bucket `mlflow` et les artefacts.

Pour effectuer un test de bout en bout (run, métrique, modèle enregistré et
artefact) :

```bash
python -m pip install mlflow==3.17.2 scikit-learn
python tests/smoke_test.py
```

Le test doit afficher un identifiant de run, une valeur RMSE et l’alias
`champion` du modèle `housing-smoke`. Les détails des services sont consultables
avec :

```bash
docker compose -f compose.yaml logs -f mlflow
```

À la fin du test :

```bash
docker compose -f compose.yaml down
```

Pour entraîner le modèle Random Forest de prédiction du prix et l’enregistrer
dans l’expérience `california-housing-random-forest` :

```bash
MLFLOW_TRACKING_URI=http://127.0.0.1:5000 python ml/src/random_forest.py
```

Le run journalise les paramètres, les métriques RMSE/MAE/R², l’empreinte des
données et le modèle `housing-random-forest` sous l’alias `champion`.