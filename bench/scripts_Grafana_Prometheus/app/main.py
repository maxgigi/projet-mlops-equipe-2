"""Serveur d'inférence minimal compatible avec le protocole KServe v1.

Route exposée : POST /v1/models/<MODEL_NAME>:predict
  Entrée  : {"instances": [[8 valeurs numériques], ...]}
  Sortie  : {"predictions": [valeur, ...]}

Le nom du modèle vient de la variable d'environnement MODEL_NAME (définie dans
le manifeste Kubernetes), ce qui permet de le changer sans modifier le code.
"""
import os
from typing import List

import joblib
from fastapi import FastAPI
from pydantic import BaseModel

MODEL_NAME = os.environ.get("MODEL_NAME", "housing-sklearn")

app = FastAPI(title=f"{MODEL_NAME} (appli témoin P5)")

# Le modèle est chargé une seule fois au démarrage du processus
model = joblib.load("model.joblib")


class PredictRequest(BaseModel):
    """Corps de requête au format KServe v1."""
    instances: List[List[float]]


@app.get("/healthz")
def healthz() -> dict:
    """Sonde de vivacité utilisée par Kubernetes (liveness/readiness)."""
    return {"status": "ok"}


@app.post(f"/v1/models/{MODEL_NAME}:predict")
def predict(req: PredictRequest) -> dict:
    """Retourne une prédiction par instance reçue."""
    predictions = model.predict(req.instances)
    return {"predictions": predictions.tolist()}
