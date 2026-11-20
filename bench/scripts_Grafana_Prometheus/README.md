# Lab P5 : observabilité et tests

Automatise l'installation du lab de test (k3s + appli témoin + Prometheus/Grafana + k6).

## Prérequis
- Deux VM Ubuntu démarrées : `lab-k8s` (cluster) et `lab-load` (générateur de charge).
- Connexion SSH par clé depuis la machine qui lance `install.sh`, `sudo` sans mot de passe.

## Utilisation (depuis l'hôte)
    ./install.sh                        # interactif
    ./install.sh --defaults             # sans question
    ./install.sh --only app,monitoring  # étapes choisies (base, app, monitoring, load, verify)

## Contenu
| Fichier | Rôle | Machine |
|---|---|---|
| install.sh | Questions, envoi des fichiers, appel des étapes | hôte |
| lib/common.sh | Fonctions partagées | toutes |
| scripts/10_base_k8s.sh | k3s, Helm, Docker, OBS-1 | lab-k8s |
| scripts/20_deploy_app.sh | Appli témoin (image, manifeste, test) | lab-k8s |
| scripts/30_monitoring.sh | Prometheus, Grafana, port-forward | lab-k8s |
| scripts/40_load_generator.sh | k6, banc de benchmark | lab-load |
| scripts/50_verify.sh | Contrôle de la chaîne de mesure | lab-k8s |
| bench/k6/load.js, bench/run_scenario.sh | Scénarios B1/B2/B5 avec répétitions | lab-load |

`config.env` (généré) ne contient aucun secret. Le mot de passe Grafana n'existe que
dans le Secret Kubernetes `grafana-admin` (exigence ENG-2).

## Problèmes connues :
-Si l'accès à grafana n'arrive pas ce faire (connexion échoué) vérifier sur la machine lab-k8s l'écoute du port 3000
-

## Au besoin faire (sur la machine hôte):
 ./install.sh --only monitoring
Cela permet de faire uniquement les étapes de vérification 

## Accés par défaut :
-Grafana     : http://192.168.122.50:3000   (identifiant : admin) mdp, faire sur la machine k8s-lab : kubectl -n monitoring get secret grafana-admin \-o jsonpath='{.data.admin-password}' | base64 -d; echo
-Prometheus  : http://192.168.122.50:9090/targets

## Benchmark : 
lancer sur lab-load  :  ~/p5/bench/run_scenario.sh (b1/b2 ou b5)
