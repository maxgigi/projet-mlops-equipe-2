"""Execute 12 Random Forest runs and journalise them dans MLflow.

Usage (depuis la racine du dépôt) :
    python ml/src/init_random_forest.py

La grille teste toutes les combinaisons de n_estimators = [50, 100, 150, 200]
et max_depth = [10, 20, None]. Chaque modèle est enregistré dans MLflow.
Le modèle ayant la plus faible RMSE reçoit l'alias « champion ».
"""

import hashlib
import json
import os
import sys
from pathlib import Path

import dotenv
import mlflow
import pandas as pd
from mlflow import MlflowClient
from mlflow.models import infer_signature
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, r2_score, root_mean_squared_error
from sklearn.model_selection import train_test_split

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CSV_PATH = DATA_DIR / "california_housing.csv"
MANIFEST_PATH = DATA_DIR / "california_housing.manifest.json"

EXPERIMENT = "california-housing"
REGISTERED_MODEL = "housing-random-forest"
ALIAS = "champion"
SEED = 42

N_ESTIMATORS_VALUES = [50, 100, 150, 200]
MAX_DEPTH_VALUES = [10, 20, None]

ENV_PATH = Path(__file__).resolve().parent.parent / ".env"
MLFLOW_TRACKING_URI = (
    os.getenv("MLFLOW_TRACKING_URI")
    or dotenv.get_key(str(ENV_PATH), "MLFLOW_URI")
    or "http://localhost:5000"
)

mlflow.set_tracking_uri(MLFLOW_TRACKING_URI)


def load_dataset() -> tuple[pd.DataFrame, pd.Series, str]:
    """Charge le jeu figé et vérifie son empreinte SHA-256."""
    if not CSV_PATH.exists():
        sys.exit(f"{CSV_PATH} absent : executez `python ml/src/prepare_data.py`")

    manifest = json.loads(MANIFEST_PATH.read_text())
    digest = hashlib.sha256(CSV_PATH.read_bytes()).hexdigest()
    if digest != manifest["sha256"]:
        sys.exit(f"Jeu de données modifié : sha256 {digest} != {manifest['sha256']}")

    df = pd.read_csv(CSV_PATH)
    return df[manifest["features"]], df[manifest["target"]], digest


def main() -> None:
    X, y, data_sha = load_dataset()
    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=SEED,
    )

    mlflow.set_experiment(EXPERIMENT)
    best_rmse = float("inf")
    best_run_id = None
    best_model_version = None
    run_count = 0

    for n_estimators in N_ESTIMATORS_VALUES:
        for max_depth in MAX_DEPTH_VALUES:
            run_count += 1
            params = {
                "algorithm": "RandomForestRegressor",
                "n_estimators": n_estimators,
                "max_depth": str(max_depth),
                "random_state": SEED,
                "test_size": 0.2,
                "n_jobs": -1,
            }
            run_name = f"rf-n{n_estimators}-depth{max_depth}"

            model = RandomForestRegressor(
                n_estimators=n_estimators,
                max_depth=max_depth,
                random_state=SEED,
                n_jobs=-1,
            )
            model.fit(X_train, y_train)
            y_pred = model.predict(X_test)

            rmse = root_mean_squared_error(y_test, y_pred)
            mae = mean_absolute_error(y_test, y_pred)
            r2 = r2_score(y_test, y_pred)

            with mlflow.start_run(run_name=run_name) as run:
                mlflow.log_params(params)
                mlflow.set_tags(
                    {
                        "data.sha256": data_sha,
                        "data.file": CSV_PATH.name,
                        "grid.run": str(run_count),
                    }
                )
                mlflow.log_metrics({"rmse": rmse, "mae": mae, "r2": r2})
                model_info = mlflow.sklearn.log_model(
                    model,
                    name="model",
                    signature=infer_signature(X_train, model.predict(X_train)),
                    input_example=X_train.head(3),
                    registered_model_name=REGISTERED_MODEL,
                    skops_trusted_types=["sklearn.tree._tree.Tree"],
                )

            if rmse < best_rmse:
                best_rmse = rmse
                best_run_id = run.info.run_id
                best_model_version = model_info.registered_model_version

            print(
                f"{run_count:02d}/12 | n_estimators={n_estimators:3d} | "
                f"max_depth={str(max_depth):4s} | rmse={rmse:.4f} | "
                f"run_id={run.info.run_id}"
            )

    if best_model_version is None:
        sys.exit("Aucun modèle n'a été enregistré.")

    client = MlflowClient()
    client.set_registered_model_alias(
        REGISTERED_MODEL,
        ALIAS,
        best_model_version,
    )

    print(f"registered_model   : {REGISTERED_MODEL}")
    print(f"champion_version   : {best_model_version}")
    print(f"champion_run_id    : {best_run_id}")
    print(f"champion_rmse      : {best_rmse:.4f}")
    print(f"champion_alias     : {ALIAS}")


if __name__ == "__main__":
    main()
