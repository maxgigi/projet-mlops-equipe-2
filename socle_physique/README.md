## Ressources machine:
Nous disposons de 4 OptiPlex 7040, de spécifications :
- Processeurs = 4
- Threads par coeurs = 2
- Coeurs par socket = 2 
- Socket = 1
- Ram 16Go pour mem et 16Go pour echange
- Mémoire totale = environ 16 241 000 KB
- Disque sda 465,8 sur 500GB 
- Attention pour machine 64, on a aussi loop0 a 100Gb

## Interfaces réseau
Ci dessous les hostnames, n° de machine, adresses MAC et adresses IPs fixes de nos machines : 
- controller 64 - 64:00:6a:88:64:a9 - 192.168.50.10
- compute1 68 - 64:00:6a:85:b3:c9 - 192.168.50.11
- compute2 67 - 64:00:6a:85:ae:f1 - 192.168.50.12
- router 60 - 64:00:6a:88:67:29 - 192.168.50.1

## Câblage
- Pour le router, brancher l'amont (WAN, réseau INSA) sur le port ethernet principal, et brancher le switch (LAN) sur l'adaptateur USB-A vers RJ45 ;
- Brancher le controller et les computes sur le switch, SANS brancher le switch au résseau INSA.
- Brancher un adaptateur supplémentaire entre le switch et 
