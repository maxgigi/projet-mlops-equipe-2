"""Entraîne et enregistre un Random Forest pour prédire le prix des logements.

Usage (depuis la racine du dépôt) :
    python ml/src/random_forest.py

Prérequis : un serveur MLflow joignable et MLFLOW_TRACKING_URI exporté, par
exemple ``http://127.0.0.1:5000``.
"""

import hashlib
import json
import os
import sys
from pathlib import Path

import dotenv

import mlflow
import numpy as np
import pandas as pd
from mlflow import MlflowClient
from mlflow.exceptions import MlflowException
from mlflow.models import infer_signature
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, r2_score, root_mean_squared_error
from sklearn.model_selection import train_test_split

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CSV_PATH = DATA_DIR / "california_housing.csv"
MANIFEST_PATH = DATA_DIR / "california_housing.manifest.json"

EXPERIMENT = "california-housing"
REGISTERED_MODEL = "california-housing"
ALIAS = "champion"
SEED = 42

ENV_PATH = Path(__file__).resolve().parent.parent / ".env"
MLFLOW_TRACKING_URI = (
    os.getenv("MLFLOW_TRACKING_URI")
    or dotenv.get_key(str(ENV_PATH), "MLFLOW_URI")
    or "http://localhost:5000"
)

mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)

def load_dataset() -> tuple[pd.DataFrame, pd.Series, str]:
    """Charge le jeu de données et vérifie son empreinte avant entraînement."""
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

    max_depth = None
    params = {
        "algorithm": "RandomForestRegressor",
        "n_estimators": 100,
        "max_depth": "None",
        "random_state": SEED,
        "test_size": 0.2,
        "seed": SEED,
    }
    model = RandomForestRegressor(
        n_estimators=params["n_estimators"],
        max_depth=max_depth,
        random_state=params["random_state"],
        n_jobs=-1,
    ).fit(X_train, y_train)
    y_pred = model.predict(X_test)
    rmse = root_mean_squared_error(y_test, y_pred)
    mae = mean_absolute_error(y_test, y_pred)
    r2 = r2_score(y_test, y_pred)

    mlflow.set_experiment(EXPERIMENT)
    with mlflow.start_run(run_name="random-forest") as run:
        mlflow.log_params(params)
        mlflow.set_tags({"data.sha256": data_sha, "data.file": CSV_PATH.name})
        mlflow.log_metrics(
            {
                "rmse": rmse,
                "mae": mae,
                "r2": r2,
            }
        )
        info = mlflow.sklearn.log_model(
            model,
            name="model",
            signature=infer_signature(X_train, model.predict(X_train)),
            input_example=X_train.head(3),
            registered_model_name=REGISTERED_MODEL,
            skops_trusted_types=["sklearn.tree._tree.Tree"],
        )

    version = info.registered_model_version
    client = MlflowClient()
    try:
        champion = client.get_model_version_by_alias(REGISTERED_MODEL, ALIAS)
    except MlflowException as exc:
        if exc.error_code != "RESOURCE_DOES_NOT_EXIST":
            raise
        champion = None

    if champion is None:
        client.set_registered_model_alias(REGISTERED_MODEL, ALIAS, version)
        champion_version = version
        champion_rmse = rmse
        promotion_status = "set as initial champion"
    else:
        champion_run = client.get_run(champion.run_id)
        champion_rmse = champion_run.data.metrics.get("rmse")
        champion_version = champion.version

        if champion_rmse is None:
            promotion_status = (
                "kept current champion: its RMSE is unavailable for comparison"
            )
        elif rmse < champion_rmse:
            client.set_registered_model_alias(REGISTERED_MODEL, ALIAS, version)
            champion_version = version
            champion_rmse = rmse
            promotion_status = "promoted: lower RMSE than current champion"
        else:
            promotion_status = "kept current champion: its RMSE is equal or lower"

    reloaded = mlflow.sklearn.load_model(f"models:/{REGISTERED_MODEL}/{version}")
    max_gap = float(np.max(np.abs(reloaded.predict(X_test) - y_pred)))

    print(f"run_id             : {run.info.run_id}")
    print(f"model_uri          : {info.model_uri}")
    print(f"registered_model   : {REGISTERED_MODEL} v{version}")
    print(f"champion           : v{champion_version} @{ALIAS}")
    print(
        "champion_rmse     : "
        + ("unavailable" if champion_rmse is None else f"{champion_rmse:.4f}")
    )
    print(f"promotion          : {promotion_status}")
    print(f"rmse               : {rmse:.4f}")
    print(f"mae                : {mae:.4f}")
    print(f"r2                 : {r2:.4f}")
    print(f"écart max rechargé : {max_gap:.2e} (doit être 0)")


if __name__ == "__main__":
    main()