# ADR-008 : Choix du moteur et du mode de serving (KServe en RawDeployment)

- **Date :** 2026-11-17
- **Statut :** Validée
- **Pôle concerné :** P4 (Serving)

## Contexte
La plateforme doit exposer les modèles enregistrés dans MLflow via une API d'inférence JSON standardisée (jalon J5 / MVP), sur un cluster Kubernetes hébergé dans un cloud privé OpenStack aux ressources limitées (sans GPU). L'installation doit être reproductible et maîtrisable dans les délais impartis avant le Go/No-Go de décembre.

## Options considérées

1. **KServe en mode Serverless (avec Knative Serving + Istio/Kourier)**
   - *Avantages :* Support natif du scale-to-zero, autoscaling basé sur la concurrence des requêtes (KPA), gestion fine des révisions et du trafic (canary).
   - *Limites :* Complexité d'installation élevée, forte consommation de ressources (RAM/CPU) sur le cluster, et risques importants de blocages réseau (webhooks, certificats, routage Ingress/Kourier) pouvant retarder le MVP.

2. **KServe en mode RawDeployment (sans Knative)**
   - *Avantages :* Utilise les objets standards de Kubernetes (Deployment, Service, HPA) tout en conservant les CRD (`InferenceService`), l'initialisation automatique depuis S3 (RustFS/MinIO) et le protocole d'inférence v1 de KServe. Permet une migration ultérieure vers le mode Serverless (jalon J6) sans réécrire le format des modèles ni les tests d'API.
   - *Limites :* Pas de scale-to-zero natif dans un premier temps (autoscaling limité au HPA sur CPU/mémoire).

3. **API personnalisée avec FastAPI (déployée via un Deployment Kubernetes classique)**
   - *Avantages :* Très léger, contrôle total sur le code Python, facile à déboguer.
   - *Limites :* Ne répond pas aux exigences du cahier des charges sur l'utilisation d'un outil de serving standardisé (KServe), oblige à coder manuellement le chargement S3 et la gestion du cycle de vie des modèles.

## Décision
Nous retenons **KServe v0.14.0 en mode RawDeployment** pour le Niveau 1 (MVP), avec `cert-manager` v1.16.2 pour la gestion des certificats des webhooks.
Ce choix permet de sécuriser la chaîne de bout en bout (MLflow -> S3 -> KServe -> API) dès le jalon J5 sans introduire la complexité réseau de Knative. Le passage au mode Serverless (Knative + Kourier) est reporté au jalon J6 (extension Niveau 2).

## Conséquences
- **Gains :** Déploiement plus léger en ressources, débogage simplifié via les objets Kubernetes natifs, validation locale déjà effectuée sur `kind`.
- **Contraintes / Vigilance :** Nécessite l'application des CRDs KServe via `kubectl apply --server-side --force-conflicts` en raison de la taille des annotations. L'autoscaling repose initialement sur le HPA standard.

## Plan B
Si KServe rencontre des blocages critiques sur le cluster cible (incompatibilité de versions, échec des webhooks ou de l'initialiseur S3) dépassant une séance de travail, l'équipe basculera sur un **MVP dégradé** : un conteneur léger **FastAPI** embarquant le modèle scikit-learn (`joblib`) et exposé via un `Deployment` et un `Service` Kubernetes classiques.
