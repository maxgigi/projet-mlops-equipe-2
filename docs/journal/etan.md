# Journal de Bord - Etan DU (P1)

## 21 octobre 2026

### Tâches :
- Lecture du cahier des charges et du planning
- Organisation de la réunion d'équipe
- Organisation de la répartition des rôles
- Configuration du switch
- Début de configuration Openstack (devstack) sur une VM

## 23 octobre 2026

### Tâches :
- VM Openstack complète avec devstack
- Début test de Kolla Ansible sur des VMs pour le futur déploiement sur les machines physiques

## 3 novembre 2026

### Tâches :
- Continue le test de Kolla Ansible sur les VMs

## 4 novembre 2026

### Tâches :
- Fini le test de Kolla Ansible sur les VMs

## 10 novembre 2026

### Tâches :
- Continue les tests sur les VM pour configurer les services (Horizon, heat)
- Révision de l'architecture et des éléments nécessaires

## 17 novembre 2026

### Tâches :
- Continue les tests sur les VMs (scripts de création des VMs openstacks)
- Correction de bug lié aux connections via adresses IP

## 18 novembre 2026

### Tâches :
- Continue les tests sur les VMs (scripts de création des VMs openstacks)

## 19 novembre 2026

### Tâches :
- Continue les tests sur les VMs (scripts de création des VMs openstacks)
- réflexion sur la configuration du switch
- réflexion sur les solutions aux manques de materiel pour les inetfaces réseaux (pour le NAT, clé wifi)


## 20 novembre 2026

### Tâches :
- configuration nouveau switch
- configuration machine physique
- début install via kolla ansible sur les machines physiques
- Correction de bug/imprévu multiple lors de l'installation


## 23 novembre 2026

### Tâches :
- finalisation de l'install via kolla-ansible
- création réseau openstack
- script provision.sh (projet [quota], user, instances ...) et destroy.sh adapté
- création des VMs pour Kubernetes


## 25 novembre 2026

### Tâches :
- correction ordre allumage (cause de problème réseau)
- Correction de problème de connexion des computes au cluster
- correction problème de problème de redémarrage des VMs
- correction connection extérieur sur le switch


## 26 novembre 2026

### Tâches :
- correction problème de connection dû au dongle/port usb défaillant (passage sur interface virtuelle avec modif de la config du switch) 
