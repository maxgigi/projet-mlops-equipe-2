"""Smoke test: logs one run with a model, registers it with alias 'champion'.

Run from your machine (no S3 credentials needed: artifacts go through the server):
    pip install mlflow==2.22.1 scikit-learn
    python smoke_test.py
"""
import mlflow
from mlflow import MlflowClient
from mlflow.models import infer_signature
from sklearn.datasets import fetch_california_housing
from sklearn.linear_model import LinearRegression
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split

mlflow.set_tracking_uri("http://localhost:5000")
mlflow.set_experiment("smoke-test")

X, y = fetch_california_housing(return_X_y=True, as_frame=True)
X_train, X_test, y_train, y_test = train_test_split(X, y, random_state=42)

with mlflow.start_run(run_name="smoke-linreg") as run:
    model = LinearRegression().fit(X_train, y_train)
    rmse = mean_squared_error(y_test, model.predict(X_test)) ** 0.5
    mlflow.log_param("model", "LinearRegression")
    mlflow.log_metric("rmse", rmse)
    mlflow.sklearn.log_model(
        model,
        artifact_path="model",
        signature=infer_signature(X_train, model.predict(X_train)),
        registered_model_name="housing-smoke",
    )
    print(f"run {run.info.run_id}  rmse={rmse:.3f}")

client = MlflowClient()
latest = max(int(v.version) for v in client.search_model_versions("name='housing-smoke'"))
client.set_registered_model_alias("housing-smoke", "champion", latest)
print(f"housing-smoke v{latest} -> alias 'champion'")
print("Check the files in the RustFS console: bucket 'mlflow' / mlflow-artifacts/")