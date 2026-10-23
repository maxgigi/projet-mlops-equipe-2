# ADR-001 : Distribution Ubuntu pour Socle Physique
- Date : 23/10/2026
- Statut : proposée
## Contexte
Notre socle physique et notre installation OpenStack se fera sur la base de trois machines : 1 Contrôleur OpenStack et 2 Computes. 
Il nous faut donc un ensemble d'interfaces afin de pouvoir aisément déployer et manipuler les différents services d'OpenStack.

## Options considérées
N'importe quelle distribution d'Ubuntu avec interface graphique devrait faire l'affaire.

## Décision
Nous avons retenu la debian-13.7.0-amd64, version la plus récente.
Nous l'avons installée sur nos trois machines :
- 67 - Contrôleur ;
- 68 - Compute-1 ;
- 64 - Compute-2.

## Conséquences


## Plan B
Si on préfère un provisionnement direct des noeuds compute au travers, par expl d'Ironic, il suffira d'écraser les installations, donc pas/peu de temps perdu à installer la debian sur les noeuds compute.
