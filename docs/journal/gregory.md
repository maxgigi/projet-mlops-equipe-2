# **Compte rendu Cavillot Grégory, Observabilités et Test**

## 21 octobre 2026

### Tâches faites
- Création de machines (K8s) en local afin d'effectuer des tests
- Mise en place de monitoring (grafana + prometheus) + vérif de la connectivité des machines créées avec ces interfaces de monitoring
- Test de charge avec résultat concluant sur la capacité des outils de monitoring à visualiser les pics de charges

### Problèmes rencontrés
- Proxmox io-error, ma machine k8s ne pouvait pas accéder à son disque et écrire sur celui-ci avant le timeout. => Freeze de ma machine. Solution : vider les machines non utilisées pour que leur espace disque puisse être réutilisé dans local-lvm
- Problème au niveau de Grafana + prometheus : non connectivité avec nos machines. (réglé en refaisant la config)

## 23 octobre 2026

### Tâches faites
- Début de la création d'un script permettant le déploiement d'outils d'observation Grafana + prométhéum sur des machines de manière automatique
- Réflexion sur de potentiels benchmarks à ajouter
- Aide des pôles P1 et P2 dans leurs tâches (installation d'infrastructure notamment d'un contrôleur sur Debian et mise en place de Kubernetes)
- Réfléxion sur la mise en place d'alternatives à Prometheus + Grafana

### Problèmes rencontrés
- N'ayant pas encore l'infrastructure du projet je ne peux pas faire de test sur celui-ci

## 17 novembre 2026

### Tâches faites
-Aide du pôle 1 avec la récupération des informations des différentes ressources utilisables

-Aide dans la réflexion de la mise en place de l'openstack sur les machines

-continuation du script d'automatisation de toute la partie observabilités et test

## 18 novembre 2026

### Tâches faites
-Finition du script et test (tout fonctionne bien)

-Aide du pôle P1 dans leur tâche

## 20 novembre 2026

### Tâches faites
- Réajustement du script et mise en place d'une documentation vis-à-vis des problèmes de connexion au Grafana et de port-forwarding.
- Aide au pôle 1 dans la finition des installations de l'infrastructure OpenStack.
- Création d'alertes envoyées par mail.
- Problème dans la mise en place d'email pour alerte Grafana, donc modification du script afin d'activer les paramètres nécessaires.(smtp)

### Problèmes rencontrés
- Différents petits problèmes liés au script notamment dans l'écoute des ports qui ne se faisait plus.

## 23 novembre 2026

### Tâches faites
- Création d'un dashboard Grafana de monitoring de la latence de requêtes et des différents aspects réseaux.
- Création d'un système de transfert et de visualisation des données en les extrayant de Grafana (permettant la visualisation dans le temps) (non fini).
- Modification du script afin d'avoir une option cleanup et d'avoir des commandes claires à faire en cas de problèmes de types erreur de création du namespace.
- Modification du script afin de régler un problème de non suppression des ports des clusters.

### Problèmes rencontrés
- Erreur de création de namespace lorsque on utilise le même nom de namespace et que l'on renvoie le script.
- Une erreur de port peut être levée si le port du cluster est déjà utilisé.

## 25 novembre 2026

### Tâches faites
- Création d'un fichier Python permettant de faire des graphiques et résumé les résultats des benchmarks afin d'en garder une trace dans le temps
- Création d'un script bench.sh permettant de lancer automatiquement le benchmarking avec les paramètres voulus qui sont demandés à l'utilisateur. Ce script permet aussi, sans toucher à la machine de test de charge, donc depuis la machine hôte, de récupérer les résultats et graphiques créés par le script Python afin de les stocker dans un dossier. Encore une fois, le dossier où seront stockés les résultats sera demandé et un dossier par défaut sera utilisé en cas de non-réponse.
- Réflexion sur la manière de placer et de redimensionner les critères d'alertes afin de les rendre plus alignées avec la finalité du projet.

### Problèmes rencontrés
- Relégation de mon idée initiale du transfert et de visualisation de données via extraction depuis Grafana pour une solution plus simple, qu'est le fichier Python générant les graphiques.

## 27 novembre 2026

### Tâches faites
- Ajout de nouveaux ADR : ADR 11 et ADR 12.


### Problèmes rencontrés

