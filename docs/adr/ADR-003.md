# ADR-003 : Base de données (backend store) de MLflow

- Date : 23/10/2026 ; révision v2 le 18/11/2026
- Statut : acceptée
- Pôle : P3 (ML, données, MLflow)

## Contexte
Le serveur MLflow enregistre dans son *backend store* les métadonnées des expériences (runs, paramètres, métriques, tags) et du Model Registry (versions, alias `champion`). C'est l'état le plus précieux de la chaîne : le perdre, c'est perdre la traçabilité des expériences et la référence du modèle déployé.

Contraintes :
- les données doivent survivre au redémarrage ou au déplacement du pod (exigence K8S-3) ;
- plusieurs étudiants enregistrent des runs en même temps, et le serveur MLflow tourne avec plusieurs workers : la base doit supporter des **écritures concurrentes** ;
- déploiement reproductible dans Kubernetes, image officielle figée, mémoire limitée.

## Critères de choix
1. Support officiel par MLflow (SQLAlchemy, migrations de schéma).
2. Écritures concurrentes sans erreur.
3. Persistance sur un volume Kubernetes (PVC).
4. Simplicité d'exploitation : sauvegarde, restauration.
5. Empreinte mémoire.

## Options considérées
| Option | Avantages | Limites |
|---|---|---|
| **PostgreSQL 16** | Supporté par MLflow ; écritures concurrentes robustes (MVCC) ; sauvegarde simple (`pg_dump`) ; image officielle figeable ; option recommandée par le sujet | Un composant avec état de plus à déployer, avec un PVC et un secret |
| MySQL 8 | Supporté par MLflow, très répandu | Aucun avantage pour notre besoin ; image plus lourde ; alternative citée par le sujet sans valeur ajoutée |
| SQLite sur PVC | Aucun serveur, simple ; plan B du sujet | Un seul écrivain à la fois (erreurs `database is locked` avec plusieurs workers ou clients) ; impose un seul worker MLflow |

## Décision
Nous retenons **PostgreSQL 16, figé en `postgres:16.15`** (version déclarée dans `ml/.env.example` et `versions.yaml`). Le mot de passe est injecté par variable d'environnement : `.env` en local, Secret Kubernetes sur le cluster, jamais dans Git.

## Validation (18/11/2026, en local uniquement)
Pile `ml/compose.yaml` sur Docker Compose : base `healthy`, schéma MLflow créé au démarrage du serveur, runs et Model Registry fonctionnels (`ml/tests/smoke_test.py`). Mémoire au repos : 103 Mio.

**À rejouer sur le cluster cible**, avec le test de persistance K8S-3 : écrire un run, supprimer le pod PostgreSQL, vérifier que le run est toujours visible.

## Conséquences
- (+) Écritures concurrentes fiables : plusieurs étudiants et workers MLflow en parallèle.
- (+) Sauvegarde et restauration simples (`pg_dump` / `pg_restore`), utiles pour J9 (reconstruction from scratch).
- (+) Empreinte faible (environ 100 Mio au repos).
- (−) Un service avec état de plus, sur un seul PVC (local-path) : pas de haute disponibilité au Niveau 1.
- (!) Montée de version de MLflow : le schéma doit être migré (`mlflow db upgrade <uri>`) avant de redémarrer le serveur. Une montée de version passe donc par une PR et une sauvegarde préalable.

## Plan B
Si PostgreSQL bloque sur le cluster (PVC en attente, pod en échec répété) : **SQLite sur PVC** avec un seul worker MLflow (`--workers 1`). Les runs déjà enregistrés sont repris par export/import, et la décision est consignée dans le journal.
