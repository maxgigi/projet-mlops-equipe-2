"""Premier run MLflow de bout en bout (« hello run ») : vérifie que la chaîne fonctionne.

Étapes : lecture du CSV figé (empreinte vérifiée) -> entraînement d'une Ridge ->
journalisation des paramètres, métriques et du modèle dans MLflow ->
enregistrement dans le Model Registry + alias -> rechargement via l'alias et
comparaison avec la prédiction locale (le critère du MVP, en miniature).

Prérequis : un serveur MLflow joignable et MLFLOW_TRACKING_URI exporté, par exemple
    export MLFLOW_TRACKING_URI=http://127.0.0.1:5000
Avec la pile de l'équipe (ml/compose.yaml, MinIO) : voir ml/README.md et
ml/.env.example pour l'URI et les variables d'accès à MinIO.
Usage (depuis la racine du dépôt) :  python ml/src/hello_run.py
"""

import hashlib
import json
import sys
from pathlib import Path

import mlflow
import numpy as np
import pandas as pd
from mlflow import MlflowClient
from mlflow.models import infer_signature
from sklearn.linear_model import Ridge
from sklearn.metrics import mean_absolute_error, r2_score, root_mean_squared_error
from sklearn.model_selection import train_test_split

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CSV_PATH = DATA_DIR / "california_housing.csv"
MANIFEST_PATH = DATA_DIR / "california_housing.manifest.json"

EXPERIMENT = "california-housing-hello"
REGISTERED_MODEL = "housing-hello"  # modèle de test, distinct du vrai « housing »
ALIAS = "champion"
SEED = 42

# Exemple de requête de l'annexe B du sujet (première ligne du jeu, valeurs arrondies).
ANNEX_SAMPLE = [[8.3252, 41.0, 6.98, 1.02, 322.0, 2.55, 37.88, -122.23]]


def load_dataset() -> tuple[pd.DataFrame, pd.Series, str]:
    manifest = json.loads(MANIFEST_PATH.read_text())
    digest = hashlib.sha256(CSV_PATH.read_bytes()).hexdigest()
    if digest != manifest["sha256"]:
        sys.exit(f"Jeu de données modifié : sha256 {digest} != {manifest['sha256']}")
    df = pd.read_csv(CSV_PATH)
    return df[manifest["features"]], df[manifest["target"]], digest


def main() -> None:
    X, y, data_sha = load_dataset()
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=SEED
    )

    params = {"algorithm": "Ridge", "alpha": 1.0, "test_size": 0.2, "seed": SEED}
    model = Ridge(alpha=params["alpha"]).fit(X_train, y_train)
    y_pred = model.predict(X_test)

    mlflow.set_experiment(EXPERIMENT)
    with mlflow.start_run(run_name="hello-ridge") as run:
        mlflow.log_params(params)
        mlflow.set_tags({"data.sha256": data_sha, "data.file": CSV_PATH.name})
        mlflow.log_metrics(
            {
                "rmse": root_mean_squared_error(y_test, y_pred),
                "mae": mean_absolute_error(y_test, y_pred),
                "r2": r2_score(y_test, y_pred),
            }
        )
        info = mlflow.sklearn.log_model(
            model,
            name="model",
            signature=infer_signature(X_train, model.predict(X_train)),
            input_example=X_train.head(3),
            registered_model_name=REGISTERED_MODEL,
        )

    version = info.registered_model_version
    client = MlflowClient()
    client.set_registered_model_alias(REGISTERED_MODEL, ALIAS, version)

    # Rechargement via l'alias, comme le fera la chaîne de déploiement.
    reloaded = mlflow.sklearn.load_model(f"models:/{REGISTERED_MODEL}@{ALIAS}")
    max_gap = float(np.max(np.abs(reloaded.predict(X_test) - y_pred)))
    annex = pd.DataFrame(ANNEX_SAMPLE, columns=X.columns)

    print(f"run_id            : {run.info.run_id}")
    print(f"model_uri         : {info.model_uri}")
    artifacts = client.get_model_version_download_uri(REGISTERED_MODEL, version)
    print(f"artefacts         : {artifacts}")
    print(f"registry          : {REGISTERED_MODEL} v{version} @{ALIAS}")
    print(f"écart max rechargé: {max_gap:.2e}  (doit être 0)")
    print(f"prédiction annexe : {reloaded.predict(annex)[0]:.4f} (x 100 000 $)")


if __name__ == "__main__":
    main()
