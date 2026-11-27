# ADR-010 : Choix de la solution pour les interfaces réseaux supplémentaires.
- Date : 27/11/2026
- Statut : Proposée
- Pôle 1.

## Contexte
Dans l'ADR-009, on mentionnait la nécessité de deux interfaces réseau supplémentaires pour nos OPtiPlex qui ne disposent initialement que d'une seule :
- Une entre notre NAT et notre Switch ;
- Une entre notre Switch et notre Controller.
Initialement, nous étions parti avec deux adaptateurs USB vers RJ45 (Ethernet). Nous avions configuré nos services pour cela, et l'ensemble socle physique + openstack (jalon 2) fonctionnait.

Cependant, à quelques reprises, l'adaptateur Switch-Controller s'est déconnecté à de multiples reprises, causant des issues pour nos VMs et pour les activités qui s'appuient dessus (Kubernetes, MLFlow..).
Ci-dessous un exemple flagrant : /img

Après quelques recherches (https://www.forum-nas.fr/threads/adaptateur-usb-3-0-rj45-2-5gb-vos-experiences.22099),
on apprend que ces adaptateurs sont très sensibles à la chauffe et à la poussière.
Les notre ne semblent pas chauffer, mais après changement de port USB, l'interface Switch-Controller n'était plus capricieuse.

## Options considérées
Quelques options s'ouvrent à nous concernant l'interface Switch-Controller :
- Le conserver, dépoussiérer régulièrement les ports, et garder en tête que ce problème existe, et arrivera occasionnellement ;
- ????

## Décision
Nous avons réussi à rapidement déployer la version Switch
(j'étais encore en train d'écrire l'ADR quand Etan a réussi).

## Conséquences
Socle Physique + Openstack fonctionnel sans s'appuyer sur deux adaptateurs usb-ethernet.

## Plan B
Si l'option Switch se révèle par la suite complexe et/ou instable,
on repassera sur l'adaptateur physique,
tout en gardant en tête qu'un simple dépoussièrage va fix nos éventuels problèmes.
