# Image de base légère
FROM python:3.11-slim

WORKDIR /app

# Dépendances d'abord : cette couche est mise en cache par Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Code, puis entraînement du modèle PENDANT la construction de l'image
# (nécessite un accès Internet au moment du build)
COPY train.py main.py ./
RUN python train.py

# Exécution sans droits root (bonne pratique, exigence ENG-2)
RUN useradd --uid 1000 appuser
USER 1000

EXPOSE 8080
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
