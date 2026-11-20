# Pôle P3 — ML, données, MLflow

## Environnement Python (uv)

L'environnement est géré par [uv](https://docs.astral.sh/uv/) en mode projet :

- `pyproject.toml` : Python 3.12 et dépendances directes, versions figées
  (alignées sur le runtime sklearn de KServe v0.14.0) ;
- `uv.lock` : arbre complet figé (dépendances transitives et empreintes) ;
- `.python-version` : uv télécharge et utilise Python 3.12 automatiquement.

Depuis ce dossier (`ml/`) :

```bash
uv sync                               # crée ml/.venv, identique à uv.lock
uv run python src/prepare_data.py     # jeu de données figé (vérifie le SHA-256)
```

`uv run` exécute dans `.venv` sans avoir à l'activer. Pour changer une version :
modifier `pyproject.toml` (et, si besoin, la date `exclude-newer`), lancer
`uv lock`, puis reporter la version dans `versions.yaml`, le tout dans une PR.
`uv lock --check` vérifie que `uv.lock` est à jour.

## Tester MLflow avec Docker Compose

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
uv run python tests/smoke_test.py
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

Pour initialiser une recherche sur une grille de 12 configurations Random
Forest et enregistrer chaque run dans l’expérience
`california-housing-random-forest` :

```bash
MLFLOW_TRACKING_URI=http://127.0.0.1:5000 python ml/src/init_random_forest.py
```

Le script teste `n_estimators` dans `[50, 100, 150, 200]` et `max_depth` dans
`[10, 20, None]`. Chaque modèle est enregistré sous
`housing-random-forest`; le modèle ayant la meilleure RMSE reçoit l’alias
`champion`.

Pour entraîner une Linear Regression et trois Ridge Regression avec
StandardScaler (`alpha` = `0.1`, `1` ou `10`) :

```bash
MLFLOW_TRACKING_URI=http://127.0.0.1:5000 python ml/src/init_linear.py
```

Les quatre modèles sont enregistrés dans l’expérience
`california-housing-linear` sous `housing-random-forest`. Le script lit la RMSE
du modèle courant portant l’alias `champion`; si aucun champion n’existe, ou si
aucune RMSE n’est disponible, le meilleur nouveau modèle devient champion.