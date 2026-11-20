# Journal de bord

## Le 21 oct

Vu qu'on travaille sur la même machine :

- **Objectif principal** : un cluster Kubernetes fonctionnel sur des VM OpenStack (jalon J3), base de toute la chaîne MLOps
- **Pour l'instant** : on construit le cluster à la main, on ne rédige pas encore les fichiers de configuration
- **Fait jusqu'ici** : infrastructure OpenStack (VM, réseau, clé SSH, groupe de sécurité) et résolution des pannes
- **Fichiers de configuration, ensuite** : `cloud-init-k8s.yaml` (déjà écrit), playbook Ansible, manifests Kubernetes
- **Logique du plan** : tout faire à la main, puis automatiser ce qui a marché, puis documenter
- **Point actuel** : fin de l'étape 1, il reste à installer Kubernetes lui-même

## Le 23 oct

Vu qu'on travaille sur une machine locale avec peu de ressources :

- **Problème de ressources** : tentative de passage du flavor `med` à `small` avant la création des fichiers, mais rien ne marchait
- **Solution adoptée** : création des fichiers et scripts pour générer l'infrastructure Kubernetes (K8s)
- **Test** : validation des scripts sur notre machine locale en utilisant une version minimale
- **Logique du plan** : créer et stocker ces fichiers sur GitHub dès maintenant, pour les utiliser sur les vraies machines une fois la partie OpenStack complète
- **Fichiers créés** : tout le code d'infrastructure est prêt et versionné dans le dossier `infra/kubernetes/`

## Le 17 nov

- **Fait** : préparation du merge des 3 fichiers ADR-005 à ADR-007 (mentionnés auparavant comme travail pour le 17/11)

## Le 18 nov

- **Organisation** : préparation du plan de travail et de répartition des tâches pour la séance du 20/11
- **Configuration** : correction et ajustement des fichiers de configuration des VM Control Plane (CP) et Workers

## Le 20 nov

- **Avancement Kubernetes (J3)** : validation des manifests et déploiements Kubernetes en environnement local
- **Point de blocage** : déploiement sur l'infrastructure cible en attente de la finalisation des machines virtuelles sur OpenStack (jalon J2)
