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

## Le 23 nov

- **Constat matériel** : les machines physiques n'ont pas 16 Go de RAM exploitables mais environ 15,5 Go, ce qui laisse moins de marge que prévu pour l'hôte et les VM
- **Décision (validée en équipe)** : RAM par VM réduite de 8 Go à 7 Go
- **Scripts Kubernetes** : scripts de configuration modifiés pour s'adapter au nouveau dimensionnement
- **Prochaine étape** : début de l'implémentation de ces scripts aujourd'hui, lors de la 2ème séance de projet d'option

## Le 27 nov

- **Constat de départ** : 4 nœuds `Ready` (Kubernetes v1.30.6), mais le control plane est surchargé (load ~12 pour 2 vCPU). `etcd`, l'API server et le `controller-manager` ont redémarré 8 à 12 fois.
- **Échec de `addons.yaml`** : deux causes distinctes.
  - **Chemins introuvables** : la tâche `copy` créait un double niveau `/root/manifests/manifests/` (slash final manquant sur `src`).
  - **`TLS handshake timeout`** sur l'API server, causé par la surcharge du CP.
- **Diagnostic** : CPU à 0 % d'idle, 59 % de temps système, 0 % de steal, et CPU invité « AMD EPYC » sur du matériel Intel. Cela suggère de l'émulation `qemu`, **mais ce n'est pas prouvé** (le type d'hyperviseur affiché par OpenStack ne permet pas de conclure).
- **Inventaire OpenStack (Kolla)** : **2 hôtes de calcul** seulement (`compute1`, `compute2`, 4 threads et ~15,5 Gio chacun). Le 3ᵉ OptiPlex est le contrôleur et n'héberge aucune VM. Les quotas du projet ne limitent pas, la contrainte est physique.
- **Décision de dimensionnement** : **1 CP (4 vCPU) seul sur `compute1`** et **2 workers (2 vCPU) sur `compute2`**, soit 4 vCPU sur 4 threads par hôte, sans surcommit. `worker3` supprimé du cluster.
  - Le CP est le composant le plus sensible à la latence, il reçoit donc tous les threads de son hôte.
  - Disque conservé à 70 Go : Nova ne réduit pas un disque lors d'un resize.
- **Mise en œuvre** : deux flavors (`k8s.cp`, `k8s.worker`) au lieu de `k8s.custom`. VM redimensionnées avec `openstack server resize` (sans recréation), une par une, avec `kubectl drain` puis `uncordon`.
- **Correctifs `addons.yaml`** : slash final sur `src` et `dest` de « Copier les manifests », attente de l'API (`/readyz`), `--validate=false` et `retries`/`until` sur les tâches qui parlent à l'API.
- **Résultat** : le timeout a disparu (API en ~2 s). Les 4 playbooks (`common`, `control-plane`, `workers`, `addons`) passent.
- **`verify.sh`** :
  - 3 nœuds `Ready`, aucun pod en erreur, `local-path (default)`, metrics-server opérationnel.
  - cert-manager : 3 pods `Running` à 0 redémarrage, `selfsigned-issuer` `READY True`.
  - Namespaces `mlops`, `models`, `monitoring` créés avec leurs quotas.
  - MTU cohérente : `ens3` 1450, `flannel.1` et `cni0` 1400 (-50 octets pour VXLAN).
  - CPU du CP à 62 % juste après l'installation, à resurveiller au repos.
- **Prochaine étape** :
  - Quotas à revoir : 3,5 CPU de `requests` pour 4 CPU de workers, trop juste avec les composants système.
  - Alignement du document d'architecture et des ADR sur les valeurs réelles.
  - Test MTU entre pods sur deux workers, test de persistance K8S-3, puis HPA et NodePort.
