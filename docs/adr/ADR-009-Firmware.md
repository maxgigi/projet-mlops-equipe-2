# ADR-009 : Choix des firmwares pour nos machines 
- Date : 20/11/2026
- Statut : Proposée
## Contexte
Après reconsidérations sur le réseau, et notamment dû au besoin de fixer des adresses IPs afin de ne pas avoir à constamment changer les fichiers de configuration, on souhaite, en plus de nos 3 machines (1 controlleur + 2 compute),
 ajouter une machine qui servirait de routeur NAT une fois placée entre le serveur DNS INSA et notre switch.

## Options considérées
N'importe quelle distribution avec nftables ou iptables peut effectuer le NAT (Network Address Translation).
En l’occurrence, les distributions Debian possèdent iptables depuis Debian 10, et il existe de la documentation et des guides quand à la configuration d'un routeur NAT.

## Décision
Nous avons retenu la Debian 13.7 (dite Trixie, image debian-13.7.0-amd64), que nous avons installée sur nos quatres machines.

La répartition des machines est la suivante :
- 64 - Contrôleur ;
- 68 - Compute-1 ;
- 67 - Compute-2 ;
- 60 - NAT.

## Conséquences
Cette architecture avec un routeur NAT va nous nécessiter du matériel, notamment pour augmenter le nombre d'interface réseau du routeur NAT, car les Optiplex utilisés n'en possèdent qu'une seule (achat adaptateur USB-C vers RJ45 ~ 10€).

## Plan B
Si la distribution choisie se révèle inadaptée, nous changerons.
