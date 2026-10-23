# ADR-001 : Distribution Ubuntu pour Machine Contrôleur
- Date : 23/10/2026
- Statut : proposée
## Contexte
Notre socle physique et notre installation OpenStack se fera sur la base de trois machines : 1 Contrôleur OpenStack et 2 Computes. 
Il nous faut donc une interface afin de pouvoir aisément déployer et manipuler les différents services d'OpenStack.

## Options considérées
N'importe quelle distribution d'Ubuntu avec interface graphique devrait faire l'affaire.
## Décision
Nous avons retenu la debian-13.7.0-amd64, version la plus récente.
## Conséquences

## Plan B
