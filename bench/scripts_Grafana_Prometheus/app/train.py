"""Entraîne un modèle de régression sur California Housing et le sauvegarde.

Le modèle est volontairement simple : l'objectif du projet est la chaîne
de déploiement et de mesure, pas la performance prédictive.
"""
import joblib
from sklearn.datasets import fetch_california_housing
from sklearn.ensemble import RandomForestRegressor

SEED = 42                      # Graine fixe : entraînement reproductible
MODEL_PATH = "model.joblib"    # Fichier produit, chargé par le serveur


def main() -> None:
    # Charge le jeu de données (8 variables, cible = prix médian)
    data = fetch_california_housing()

    # Petite forêt aléatoire : assez de calcul pour que la latence soit mesurable
    model = RandomForestRegressor(n_estimators=100, random_state=SEED, n_jobs=1)
    model.fit(data.data, data.target)

    joblib.dump(model, MODEL_PATH)
    print(f"Modèle sauvegardé dans {MODEL_PATH}")


if __name__ == "__main__":
    main()
