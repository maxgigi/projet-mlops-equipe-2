"""Smoke test of the MLflow stack: one run, one registered model, alias 'champion'.

Checks, end to end: the server records the run, the model artifact is uploaded
(through the server: no S3 credentials needed on the client), the model is
registered with the alias 'champion', and reloading it via the alias gives the
same predictions as the local model.

Prerequisites: the stack is running (ml/compose.yaml) and the frozen dataset exists
(`uv run python src/prepare_data.py`). From the ml/ folder:
    uv run python tests/smoke_test.py
The server defaults to http://localhost:5000 (override with MLFLOW_TRACKING_URI).
Exits with a non-zero code if a check fails.
"""

import hashlib
import json
import os
import sys
from pathlib import Path

import mlflow
import numpy as np
import pandas as pd
from mlflow import MlflowClient
from mlflow.models import infer_signature
from sklearn.linear_model import LinearRegression
from sklearn.metrics import root_mean_squared_error
from sklearn.model_selection import train_test_split

DATA_DIR = Path(__file__).resolve().parent.parent / "data"
CSV_PATH = DATA_DIR / "california_housing.csv"
MANIFEST_PATH = DATA_DIR / "california_housing.manifest.json"

EXPERIMENT = "smoke-test"
REGISTERED_MODEL = "housing-smoke"
ALIAS = "champion"
SEED = 42


def load_frozen_dataset() -> tuple[pd.DataFrame, pd.Series]:
    """Same frozen data as training: refuse to run if the CSV differs from the manifest."""
    if not CSV_PATH.exists():
        sys.exit(f"{CSV_PATH} missing: run `uv run python src/prepare_data.py` first")
    manifest = json.loads(MANIFEST_PATH.read_text())
    digest = hashlib.sha256(CSV_PATH.read_bytes()).hexdigest()
    if digest != manifest["sha256"]:
        sys.exit(f"Dataset modified: sha256 {digest} != {manifest['sha256']}")
    df = pd.read_csv(CSV_PATH)
    return df[manifest["features"]], df[manifest["target"]]


def main() -> None:
    # MLflow 3.17 would otherwise download artifacts directly from S3 with presigned
    # URLs signed for the internal endpoint (http://rustfs:9000), unreachable from
    # outside the stack network: force downloads through the MLflow server (ADR-004).
    os.environ.setdefault("MLFLOW_ENABLE_PROXY_MULTIPART_DOWNLOAD", "false")
    mlflow.set_tracking_uri(
        os.environ.get("MLFLOW_TRACKING_URI", "http://localhost:5000")
    )
    mlflow.set_experiment(EXPERIMENT)

    X, y = load_frozen_dataset()
    X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=SEED)
    model = LinearRegression().fit(X_train, y_train)
    y_pred = model.predict(X_test)

    with mlflow.start_run(run_name="smoke-linreg") as run:
        mlflow.log_param("model", "LinearRegression")
        mlflow.log_metric("rmse", root_mean_squared_error(y_test, y_pred))
        info = mlflow.sklearn.log_model(
            model,
            name="model",
            signature=infer_signature(X_train, model.predict(X_train)),
            registered_model_name=REGISTERED_MODEL,
        )

    client = MlflowClient()
    version = info.registered_model_version
    client.set_registered_model_alias(REGISTERED_MODEL, ALIAS, version)

    # Checks: alias resolves to this version, and the reloaded model predicts identically.
    resolved = client.get_model_version_by_alias(REGISTERED_MODEL, ALIAS)
    assert resolved.version == str(
        version
    ), f"alias -> v{resolved.version}, expected v{version}"
    reloaded = mlflow.sklearn.load_model(f"models:/{REGISTERED_MODEL}@{ALIAS}")
    max_gap = float(np.max(np.abs(reloaded.predict(X_test) - y_pred)))
    assert (
        max_gap == 0.0
    ), f"reloaded model differs from local model (max gap {max_gap})"

    print(f"run {run.info.run_id}  rmse={root_mean_squared_error(y_test, y_pred):.3f}")
    print(
        f"{REGISTERED_MODEL} v{version} -> alias '{ALIAS}', reloaded predictions identical"
    )
    print(
        "SMOKE TEST OK. Artifacts: RustFS console, bucket 'mlflow' / mlflow-artifacts/"
    )


if __name__ == "__main__":
    main()
