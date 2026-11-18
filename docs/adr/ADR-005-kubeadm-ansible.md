# ADR-005 : kubeadm et Ansible pour déployer le cluster Kubernetes

- Date : 23/10/2026
- Statut : proposée

## Contexte
Le cluster prévu compte 4 VM : 1 control plane (4 vCPU / 8 Go) et 3 workers (4 vCPU / 12 Go chacun), soit 16 vCPU et 44 Go, hébergées sur OpenStack. Le déploiement doit être reproductible et maîtrisé par l'équipe.

## Options considérées
| Option | Avantages | Inconvénients |
|---|---|---|
| kubeadm + Ansible | Kubernetes « upstream », contrôle fin, reproductible via playbooks, forte valeur pédagogique | Mises à jour, certificats et etcd à gérer soi-même ; plus long à mettre en place |
| k3s | Très léger, installation rapide | Distribution allégée, moins représentative d'un cluster standard |
| RKE2 | Durci, orienté production | Moins de documentation |
| Kubespray | Basé sur kubeadm + Ansible, clé en main | Gros projet à comprendre, moins de maîtrise des détails |

## Décision
Nous retenons **kubeadm piloté par des playbooks Ansible**. Raison principale : maîtriser chaque étape du cluster et obtenir un déploiement rejouable.

## Conséquences
- (+) Déploiement reproductible, versionné dans le dépôt.
- (+) Compréhension approfondie du fonctionnement du cluster.
- (−) Cycle de vie (mises à jour, rotation des certificats, sauvegarde d'etcd) à la charge de l'équipe.
- (−) Control plane unique : pas de haute disponibilité.
- Validation actuelle : (kind / Proxmox / OpenStack) . Ces essais hors plateforme ne valent pas pour la cible ; **à rejouer sur OpenStack**.

## Plan B
Si kubeadm prend trop de temps ou échoue sur la plateforme cible, basculer sur k3s ou Kubespray en conservant les mêmes VM.
