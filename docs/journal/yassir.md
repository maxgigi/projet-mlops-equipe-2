# Journal de bord - 21/10/2026 (Bloc 1)

- P4 (Serving) : mise en place et validation d'un environnement de dev local avec kind sous Debian.
- Installation réussie de cert-manager v1.16.2 et KServe v0.14.0 en mode RawDeployment.
- Résolution du problème de taille de CRD via `kubectl apply --server-side --force-conflicts`.
- Déploiement du modèle témoin scikit-learn (`sklearn-iris`) et appel d'inférence JSON validé (`{"predictions":[1,1]}`).
- Prochaines étapes : rédaction de l'ADR Serving pour J1 et coordination avec P3 sur le format des modèles MLflow/MinIO.

---

## Journal de bord - 17/11/2026 (Bloc 2 — Architecture & Jalon J1)

- **Conception et spécification de l'architecture Serving (Document v0) :** Rédaction complète de la section *Serving* du document d'architecture, détaillant le cycle de vie des modèles, l'exposition réseau (protocole v1), la compatibilité des runtimes (`scikit-learn` 1.5.1) et l'intégration prévue avec le stockage objet S3 (RustFS) et MLflow.
- **Rédaction formelle de l'ADR-008 (`docs/adr/ADR-008.md`) :** Analyse comparative approfondie des stratégies de déploiement (KServe `RawDeployment` vs `Serverless`/Knative vs API `FastAPI` dédiée). Formalisation de la décision technique pour sécuriser le jalon MVP (J5) sur une infrastructure OpenStack contrainte en ressources (sans GPU), incluant l'étude des conséquences et la définition d'un Plan B.
- **Structuration et standardisation des livrables `serving/` :** Consolidation de l'arborescence technique du pôle P4 avec les manifests cibles (`InferenceService`), les jeux de tests d'inférence JSON et la documentation de déploiement reproductible (`README.md`).
- **Mise en conformité J1 et traçabilité Git :** Prise en compte des retours du tuteur sur le dossier d'architecture v0 pour garantir l'alignement strict entre les choix documentés et les fichiers d'ADR versionnés avant l'interrogation orale du 20 novembre.
- **Prochaines étapes :** Préparation de la soutenance orale J1 (justification des choix Serving et flux globaux) et coordination avec le pôle P3 (suppléance) sur la configuration des `Secrets` et `ServiceAccounts` S3 pour connecter KServe au Model Registry.
