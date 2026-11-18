# Journal de bord Max

## 21/10/2026

- Ai participé à la réunion d'équipe ;
- En tant que Head P6 nouvellement élu, ai mis en place le dépôt git (création du dépôt, ossature, collaborateurs...) ;
- Ai maintenu le journal de bord d'équipe (2026-10-21.md) ;
- Ai effectué les communications avec le responsable de projet (M. Adell) ;

## 21/10/2026

- Ai tenu la réunion d'équipe + journal 2026-10-23.md ;
- P6 - Ai préparé le template ADR ;
- Couche physique - Clé bootable Rufus, Debian 13.7.xx avec interface graphique sur la machine contrôleur (OptiFlex 67);
- Le DHCP Switch fonctionne : L'internet est bien délivré à nos machines physiques.

## 03/11/2026

- En autonomie, ai mis en place le document d'architecture v0, et ai documenté la partie Socle Physique et Cloud OpenStack du projet ;

## 10/11/2026

- Ai continué à préparer la couche physique ;
- Installation des outils Kolla-Ansible sur les machines ;
- Préparation d'une 4ème machine (60) qui servira de NAT.

## 17/11/2026

- su - ; nano /etc/resolv.conf ; search google.com ; nameserver 8.8.8.8 -> fix aux problèmes réseau salles d'options ;
- Communications tuteur + équipe + pôles .

## 17/11/2026 - 17h-18h40

- La machine 60 n'arrive pas à trouver les miroirs debian. J'ai effectué l'installation de debian en salle d'option ainsi qu'en salle 213 sans succès. Le DHCP fonctionne, mais le manque de miroir nous passe dans une install minimale. Je ne sais pas si c'est la machine qui est cassée ( potentiellement groupe précédent qui bidouillé ) ou si c'est réseau INSA qui où que j'aille me tourmente.
