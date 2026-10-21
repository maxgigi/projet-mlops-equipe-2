# **Compte rendu Cavillot Grégory, Observabilités et Test**

## 21 octobre 2026

### Tâches faites
- Création de machines (K8s) en local afin d'effectuer des tests
- Mise en place de monitoring (grafana + prometheus) + vérif de la connectivité des machines créées avec ces interfaces de monitoring
- Test de charge avec résultat concluant sur la capacité des outils de monitoring à visualiser les pics de charges

### Problèmes rencontrés
- Proxmox io-error, ma machine k8s ne pouvait pas accéder à son disque et écrire sur celui-ci avant le timeout. => Freeze de ma machine. Solution : vider les machines non utilisées pour que leur espace disque puisse être réutilisé dans local-lvm
- Problème au niveau de Grafana + prometheus : non connectivité avec nos machines. (réglé en refaisant la config)

