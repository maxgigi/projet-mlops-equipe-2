# Journal de bord - 21/10/2026 (Bloc 1)

- P4 (Serving) : mise en place et validation d'un environnement de dev local avec kind sous Debian.
- Installation réussie de cert-manager v1.16.2 et KServe v0.14.0 en mode RawDeployment.
- Résolution du problème de taille de CRD via `kubectl apply --server-side --force-conflicts`.
- Déploiement du modèle témoin scikit-learn (`sklearn-iris`) et appel d'inférence JSON validé (`{"predictions":[1,1]}`).
- Prochaines étapes : rédaction de l'ADR Serving pour J1 et coordination avec P3 sur le format des modèles MLflow/MinIO.
