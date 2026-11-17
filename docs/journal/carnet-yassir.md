# Carnet de bord individuel — Yassir Benhaddouche (Pôle P4 Serving)

## Semaines S03 à S07 (Octobre – 17 Novembre 2026) — Heures effectuées : 6,5 h

### Tâches réalisées
- **Dé-risquage précoce de la couche Serving (démarrage indépendant) :** Mise en place et validation complète d'un environnement Kubernetes local isolé (`kind` sous Debian) afin d'anticiper l'intégration avant la livraison de l'infrastructure OpenStack.
- **Déploiement et configuration de la stack KServe :** Installation de `cert-manager` (v1.16.2) et déploiement de KServe (v0.14.0) avec ses runtimes (`kserve-cluster-resources`) configurés en mode `RawDeployment` (sans dépendance critique à Knative pour sécuriser le MVP J5).
- **Validation fonctionnelle de bout en bout :** Déploiement d'un `InferenceService` témoin (`sklearn-iris`) et validation automatisable de l'API d'inférence via le protocole standard v1 (`JSON -> prédiction`).
- **Structuration du dépôt et livrables d'architecture (J1) :** Création de l'arborescence `serving/` (manifests cibles, payload de test JSON, procédure d'installation reproductible dans `serving/README.md`) et rédaction formelle de l'**ADR-008** justifiant le choix de KServe en mode `RawDeployment` ainsi que le Plan B (repli FastAPI).

### Difficultés rencontrées et diagnostics
- **Dépassement de taille des métadonnées sur les CRDs KServe :** Rejet de `inferenceservices.serving.kserve.io` par l'API server (`metadata.annotations: Too long: may not be more than 262144 bytes`) dû à l'annotation `last-applied-configuration` du client-side apply. Résolu par l'utilisation de `kubectl apply --server-side --force-conflicts`.
- **Évolution des artefacts KServe v0.14.0 :** Adaptation des manifests au nouveau packaging (`kserve-cluster-resources.yaml`) et ajustement des sélecteurs de labels (`control-plane=kserve-controller-manager`) pour le monitoring de disponibilité.

### Apprentissages
- Maîtrise de l'architecture interne de KServe (webhooks d'admission, injection TLS via `cert-manager`, cycle de vie d'un `InferenceService` en mode `RawDeployment`).
- Gestion des CRDs volumineuses sous Kubernetes via le *Server-Side Apply*.

### Priorités pour la semaine suivante
- Coordination avec le pôle P3 (suppléance) sur le format d'export des modèles `scikit-learn` (v1.5.1) et préparation de l'authentification S3 (RustFS) pour KServe.
- Préparation à l'interrogation du jalon J1 (architecture et justification de l'ADR-008).
