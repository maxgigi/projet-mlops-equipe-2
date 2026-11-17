# ADR-007 : local-path-provisioner pour le stockage persistant du cluster

- Date : [23/10/2026]
- Statut : proposée

## Contexte
Plusieurs composants ont besoin de volumes persistants : PostgreSQL 16, MLflow, stockage objet (RustFS). Le cluster doit rester simple et peu gourmand en ressources.

## Options considérées
| Option | Avantages | Inconvénients |
|---|---|---|
| local-path-provisioner | Très simple, aucune dépendance, performant (disque local) | Volume lié à un nœud, aucune réplication |
| Cinder CSI (OpenStack) | Volumes détachables et rattachables à un autre nœud, intégré à la plateforme | Dépend de la bonne configuration de Cinder (stockage à décrire dans le socle) |
| Longhorn | Réplication entre nœuds | Consomme CPU, mémoire et disque |
| Ceph / Rook | Solution complète | Trop lourd pour 44 Go de mémoire au total |
| NFS | Simple, partagé | Point unique de défaillance, performances limitées |

## Décision
Nous retenons **local-path-provisioner**. Raison principale : simplicité et faible empreinte. Version : [à compléter, à figer dans `versions.yaml`].

## Conséquences
- (+) Aucun composant lourd à déployer ni à dimensionner.
- (−) Si un worker est perdu, les données de ses volumes sont indisponibles ou perdues (PostgreSQL, MLflow).
- (−) Les pods avec état sont rattachés à un nœud donné.
- Mitigation : sauvegardes régulières de PostgreSQL et des artefacts MLflow vers [à compléter].
- Validation actuelle : [à compléter]. **À rejouer sur OpenStack**.

## Plan B
Passer à Cinder CSI (si Cinder est disponible sur le socle) ou à Longhorn pour les volumes qui exigent de la résilience.
