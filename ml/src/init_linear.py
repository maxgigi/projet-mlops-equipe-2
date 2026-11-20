"""Execute Linear and Ridge regressions and compare them with the MLflow champion.

Usage (depuis la racine du dépôt) :
    python ml/src/init_linear.py

Exécute une Linear Regression ainsi que trois Ridge Regression avec un
StandardScaler, pour les alpha 0.1, 1 et 10. Chaque modèle est enregistré dans
le même Model Registry que les autres expériences de logement. L'alias
« champion » est conservé seulement si son RMSE est inférieur ou égal à ceux
des nouveaux modèles.
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
from mlflow.exceptions import MlflowException
from mlflow.models import infer_signature
from sklearn.linear_model import LinearRegression, Ridge
from sklearn.metrics import mean_absolute_error, r2_score, root_mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CSV_PATH = DATA_DIR / "california_housing.csv"
MANIFEST_PATH = DATA_DIR / "california_housing.manifest.json"

EXPERIMENT = "california-housing"
REGISTERED_MODEL = "housing-random-forest"
ALIAS = "champion"
SEED = 42
RIDGE_ALPHAS = [0.1, 1.0, 10.0]

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


def get_current_champion(
    client: MlflowClient,
) -> tuple[str | None, float | None]:
    """Retourne la version et la RMSE du champion actuel, si disponibles."""
    try:
        champion = client.get_model_version_by_alias(REGISTERED_MODEL, ALIAS)
    except MlflowException:
        return None, None

    run = client.get_run(champion.run_id)
    rmse = run.data.metrics.get("rmse")
    return champion.version, float(rmse) if rmse is not None else None


def main() -> None:
    X, y, data_sha = load_dataset()
    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=SEED,
    )

    client = MlflowClient()
    champion_version, champion_rmse = get_current_champion(client)

    if champion_version is None:
        print("Champion actuel : aucun")
    elif champion_rmse is None:
        print(f"Champion actuel : v{champion_version} (RMSE indisponible)")
    else:
        print(
            f"Champion actuel : v{champion_version} "
            f"(RMSE={champion_rmse:.4f})"
        )

    mlflow.set_experiment(EXPERIMENT)
    candidates = [("LinearRegression", None, LinearRegression())]
    candidates.extend(
        (
            "Ridge",
            alpha,
            Pipeline(
                [
                    ("scaler", StandardScaler()),
                    ("ridge", Ridge(alpha=alpha)),
                ]
            ),
        )
        for alpha in RIDGE_ALPHAS
    )

    best_candidate_version = champion_version
    best_candidate_rmse = champion_rmse
    best_candidate_run_id = None

    for index, (model_name, alpha, model) in enumerate(candidates, start=1):
        if alpha is None:
            run_name = "linear-regression"
            params = {
                "algorithm": "LinearRegression",
                "test_size": 0.2,
                "random_state": SEED,
            }
        else:
            run_name = f"ridge-alpha-{alpha}"
            params = {
                "algorithm": "Ridge",
                "alpha": alpha,
                "scaler": "StandardScaler",
                "test_size": 0.2,
                "random_state": SEED,
            }

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
                    "model.family": model_name,
                }
            )
            mlflow.log_metrics({"rmse": rmse, "mae": mae, "r2": r2})
            model_info = mlflow.sklearn.log_model(
                model,
                name="model",
                signature=infer_signature(X_train, model.predict(X_train)),
                input_example=X_train.head(3),
                registered_model_name=REGISTERED_MODEL,
            )

        candidate_version = model_info.registered_model_version
        status = "not a champion"
        if best_candidate_rmse is None or rmse < best_candidate_rmse:
            status = "new champion"
            best_candidate_rmse = rmse
            best_candidate_version = candidate_version
            best_candidate_run_id = run.info.run_id

        alpha_label = "n/a" if alpha is None else str(alpha)
        print(
            f"{index}/4 | model={model_name:18s} | alpha={alpha_label:4s} | "
            f"rmse={rmse:.4f} | {status} | "
            f"version={candidate_version}"
        )

    if best_candidate_version is None:
        sys.exit("Aucun modèle n'a été enregistré.")

    client.set_registered_model_alias(
        REGISTERED_MODEL,
        ALIAS,
        best_candidate_version,
    )

    print(f"registered_model : {REGISTERED_MODEL}")
    print(f"champion_version : {best_candidate_version}")
    if best_candidate_run_id is not None:
        print(f"champion_run_id  : {best_candidate_run_id}")
    print(f"champion_rmse    : {best_candidate_rmse:.4f}")
    print(f"champion_alias   : {ALIAS}")


if __name__ == "__main__":
    main()
