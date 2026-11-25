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
- Fix permanent :
  ```
  nmcli con mod "Wired connection 1" ipv4.dns "8.8.8.8 1.1.1.1" ipv4.ignore-auto-dns yes
  nmcli con up "Wired connection 1"
  ```
- Communications tuteur + équipe + pôles .

## 18/11/2026 - 17h-18h40

- La machine 60 n'arrive pas à trouver les miroirs debian. J'ai effectué l'installation de debian en salle d'option ainsi qu'en salle 213 sans succès. Le DHCP fonctionne, mais le manque de miroir nous passe dans une install minimale. Je ne sais pas si c'est la machine qui est cassée ( potentiellement groupe précédent qui bidouillé ) ou si c'est réseau INSA qui où que j'aille me tourmente.

## 19/11/2026

- Machine 60 ok, c'était 'juste' le DNS INSA (encore) qui délivre pas le réseau comme il faut. Le fix était de corriger le DNS durant l'installation initiale : Ctrl+Alt+F2 ; echo "nameserver 8.8.8.8" > /etc/resolv.conf ; echo "nameserver 1.1.1.1" >> /etc/resolv.conf ; Alt+F5 ; <- Avant d'atteindre l'étape miroir ;
- Recherche sur la mise en place d'un NAT pour cette machine.

## 20/11/2026

- Ai commencé la configuration du routeur NAT, sur la base de IPs fixes associées aux adresses MACs des machines.
- Monsieur Ferrere nous a fourni un premier adaptateur USB-A vers RJ45, qui nous permettra de tester le bon fonctionnement du NAT une fois le switch configuré et l'ensemble des machines branchées (conformément à nos schémas d'architecture).
- Le socle physique fonctionne ! Le NAT délivre correctement le réseau et les IPs fixes au travers du switch. Le pôle 1 peut désormais s'open la stack 😋.

## 23/11/2026

- Petite réorganisation physique après incident (qlqn à fait poum à cause d'un fil ^^' pardon pour ça) ;
- Monsieur Ferrere nous a fourni un second adaptateur réseau, qui branché entre le switch et le controller, servira d'interface réseau pour Neutron ;
- Continue la documentation du déploiement socle physique, ainsi que le bon maintien du dépôt.

## 25/11/2026

- Suis capable de relancer le service OpenStack, grâce à la bonne documentation ;
- Aide P2 sur l'installation si il rencontre un problème lié au socle physique ;
- Continue gentiment la documentation et le maintien du dépôt.

