# ADR-004 : Stockage objet des artefacts MLflow (RustFS)

- Date : 23/10/2026 ; révision v2 le 18/11/2026
- Statut : acceptée
- Pôle : P3 (ML, données, MLflow), en lien avec P4 (Serving)

## Contexte
MLflow a besoin d'un stockage pour les artefacts (modèles, fichiers produits par les runs). Ce stockage est aussi lu par KServe : le *storage-initializer* télécharge le modèle depuis une URI `s3://` avant de démarrer le pod de prédiction. Il nous faut donc un stockage **compatible S3**.

Contraintes :
- cloud privé : pas de service S3 public (AWS, GCP, Azure exclus) ;
- exécution dans le cluster Kubernetes, sur des VM OpenStack à la mémoire limitée (bilan de capacité, remarque du 15/11) ;
- versions figées dans `versions.yaml`, avec une image officielle maintenue ;
- un seul nœud de stockage suffit au Niveau 1 (pas de redondance exigée).

Fait nouveau depuis la v1 : **MinIO, voie recommandée par le sujet, n'est plus une option maintenue**. Sa version communautaire n'est plus publiée en binaires ni en images officielles depuis octobre 2025, est passée en mode maintenance en décembre 2025, et son dépôt a ensuite été archivé (2026).

## Critères de choix
1. Compatibilité S3 avec boto3 en adressage *path-style* (utilisé par MLflow et par KServe).
2. Image officielle maintenue, avec des versions stables que l'on peut figer.
3. Licence libre.
4. Empreinte mémoire, au vu du bilan de capacité.
5. Maturité du projet.
6. Simplicité en mono-nœud.

## Options considérées
| Option | Avantages | Limites |
|---|---|---|
| **RustFS 1.0.x** | S3 compatible, Apache-2.0 ; version stable 1.0.0 publiée le 16/09/2026, correctifs réguliers sur la branche 1.0 (1.0.1 → 1.0.6) ; très léger (36 Mio mesurés au repos) ; déjà validé dans notre pile locale | Projet jeune (stable depuis 2 mois) : moins de retours d'expérience que MinIO |
| MinIO (dernière image communautaire) | Référence historique, très documentée, citée par le sujet | Plus de mises à jour ni d'image officielle : failles futures non corrigées ; les images restantes sont des reconstructions tierces |
| SeaweedFS (passerelle S3) | Apache-2.0, mature | Plusieurs composants (master, volume, filer) : plus lourd à opérer pour notre besoin |
| Garage | Léger, conçu pour l'auto-hébergement | AGPL ; sous-ensemble de l'API S3 ; configuration de la topologie obligatoire même en mono-nœud |
| Swift via `s3api` (OpenStack) | Natif du cloud déployé ; répond à OS-7 (N3) | Dépend du déploiement Swift par P1 (N2) : non disponible pour le MVP |
| Volume local (PVC, `file://`) | Aucun service supplémentaire | Pas d'API S3 : KServe devrait monter le volume (`pvc://`), ce qui couple serving et stockage |

## Décision
Nous retenons **RustFS en version stable figée** :
- serveur `rustfs/rustfs:1.0.6` (version stable la plus récente de la branche 1.0 au 18/11/2026) ;
- client `rustfs/rc:v0.1.37` pour la création du bucket (plus de tag `latest`) ;
- versions déclarées dans `ml/.env.example` et dans `versions.yaml`.

Ce choix satisfait les six critères. Il remplace la v1 de cet ADR, qui utilisait une version alpha (`1.0.0-alpha.83`) et un client non figé.

## Validation (18/11/2026, en local uniquement)
Pile `ml/compose.yaml` (PostgreSQL 16.15, RustFS 1.0.6, MLflow 3.17.2) sur Docker Compose :
- services `healthy`, bucket créé ;
- `ml/tests/smoke_test.py` réussi : run enregistré, modèle déposé dans RustFS, alias `champion` posé, modèle rechargé via l'alias avec des prédictions identiques ;
- artefacts présents dans le bucket sous `mlflow-artifacts/<id_expérience>/models/m-<id>/artifacts/` ;
- mémoire au repos : RustFS 36 Mio, PostgreSQL 103 Mio.

**Ces essais ne valent pas pour la plateforme cible : ils sont à rejouer sur le cluster OpenStack.**

## Conséquences
- (+) Stockage S3 maintenu et figé : réponse au risque « version alpha » (remarque du 15/11).
- (+) Très faible consommation mémoire.
- (+) MLflow et KServe ne dépendent que de l'API S3 : changer de stockage ne demande que de modifier l'endpoint et les identifiants.
- (−) Projet jeune : un bogue reste possible, d'où le plan B.
- (−) Un seul volume (PVC local-path) : pas de redondance ; acceptable au Niveau 1.
- (!) **Téléchargements directs (*presigned*)**. MLflow 3.17.2 annonce le téléchargement multipart quand les artefacts sont servis via S3. Le client télécharge alors directement depuis S3, avec des URL signées pour l'endpoint interne (`http://rustfs:9000` en Compose, le nom de Service en Kubernetes), injoignable depuis un poste hors de ce réseau : le chargement du modèle reste bloqué. Ce comportement est indépendant de RustFS. Contournement : côté client, `MLFLOW_ENABLE_PROXY_MULTIPART_DOWNLOAD=false`, pour que les téléchargements passent par le serveur MLflow. Cette variable est positionnée dans les scripts P3.
- (!) **Lien avec KServe** : le registry renvoie des URI `mlflow-artifacts:/…` ; le `storageUri` de l'InferenceService doit être l'URI `s3://mlflow/mlflow-artifacts/…/artifacts/` correspondante. Le format du fichier de modèle (`model.skops` par défaut en MLflow 3.17.2) est à trancher avec P4 (ADR-008).
- (!) Les identifiants S3 ne sont jamais versionnés : `.env` en local, Secret Kubernetes sur le cluster.

## Plan B
1. Bogue bloquant dans une version 1.0.x : revenir à la version 1.0.x précédente, puis la figer.
2. RustFS inutilisable : **SeaweedFS** en passerelle S3. Seuls l'endpoint et les identifiants changent pour MLflow et KServe.
3. Dernier recours : artefacts sur volume (`--artifacts-destination file:///…`) et modèle servi par KServe via `pvc://`.
4. Piste N2/N3 : si P1 déploie Swift, comparer Swift (`s3api`) et RustFS avec les mêmes charges (exigence OS-7).
