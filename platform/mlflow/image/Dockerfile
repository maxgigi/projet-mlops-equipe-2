# Image du serveur MLflow pour le cluster (pôle P3).
# L'image officielle ne contient ni le pilote PostgreSQL ni le client S3 : on les
# ajoute à la construction (versions figées) au lieu de les installer au démarrage
# du pod, qui dépendrait alors d'Internet et de versions non figées.
#
# SQLAlchemy 2.1 (inclus dans l'image) utilise psycopg 3 par défaut pour les URI
# postgresql:// : c'est ce pilote qu'il faut installer, pas psycopg2.
#
# Construction : docker build -t mlops/mlflow-server:3.17.2-2 platform/mlflow/image
FROM ghcr.io/mlflow/mlflow:v3.17.2

RUN pip install --no-cache-dir \
        "psycopg[binary]==3.3.9" \
        boto3==1.43.116 \
    && useradd --uid 10001 --create-home --shell /usr/sbin/nologin mlflow

# Conteneur non-root (ENG-2).
USER 10001
WORKDIR /home/mlflow
EXPOSE 5000
