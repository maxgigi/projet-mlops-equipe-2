# ADR-11 – Stratégie de collecte, d'analyse et d'export des benchmarks

-Date : 27/11/2026

-Statut : Proposée


## 1. Contexte

Dans le cadre du projet Cloud privé et MLOps, le pôle P5 est responsable de l'observabilité de la plateforme Kubernetes et de la réalisation des benchmarks.

L'environnement repose actuellement sur les composants suivants :

- **k6** : génération de charge et production des résultats des tests.
- **Prometheus** : collecte des métriques de l'infrastructure Kubernetes.
- **Grafana** : visualisation et analyse des métriques.
- **Python** : analyse des résultats k6, agrégation des répétitions, interrogation de Prometheus et génération des graphiques.

Un script Python (`analyze.py`) est déjà disponible. Il permet notamment :
- La lecture des fichiers JSON produits par k6 avec `--summary-export`.
- La récupération des métadonnées associées aux exécutions.
- Le calcul des indicateurs de latence p50, p95 et p99.
- Le calcul du débit et du taux d'erreur.
- L'agrégation des répétitions avec médiane, minimum, maximum et écart-type.
- La génération de fichiers CSV (`runs.csv` et `summary.csv`).
- La génération de graphiques PNG.
- L'interrogation de l'API Prometheus pour produire des timelines de performance.

Le script constitue donc une première brique d'analyse et de centralisation des résultats.

Cependant, plusieurs limites sont identifiées :

- Les séries temporelles Prometheus utilisées pour les graphiques ne sont pas archivées sous forme de CSV.
- Les données k6 exploitées proviennent de résumés de tests et ne représentent pas l'ensemble des requêtes individuelles.
- Les métadonnées de reproductibilité ne sont pas toutes intégrées à l'analyse.
- Les fiches d'expérience ne sont pas générées automatiquement.
- Les exports natifs de Grafana ne sont pas intégrés à la chaîne Python.
- Certains scénarios nécessitent une analyse complémentaire de leurs indicateurs spécifiques.

La question est donc de déterminer quelle architecture doit être retenue pour centraliser, exporter et conserver les résultats des benchmarks de manière reproductible.

## 2. Besoins et contraintes

La solution doit répondre aux exigences du cahier des charges, notamment :

- Au moins trois répétitions par scénario de benchmark.
- Calcul de la médiane et de la dispersion des résultats.
- Conservation des résultats bruts et exploitables au format CSV.
- Export des dashboards Grafana au format JSON.
- Production d'un tableau de synthèse.
- Traçabilité de chaque expérience : identifiant, date, commit Git, configuration, hypothèse, protocole, résultats, interprétation et limites.
- Possibilité de comparer les résultats entre différentes campagnes et configurations.
- Réutilisation de l'environnement actuel sans ajouter une infrastructure inutilement complexe.

Les scénarios concernés sont B0 à B7 :
- B0 : opérations OpenStack.
- B1 : référence.
- B2 : montée en charge.
- B3 : limites de ressources.
- B4 : cold start.
- B5 : autoscaling.
- B6 : modèle avancé.
- B7 : comparaison Swift et MinIO.

## 3. Options considérées

### Option A – Export manuel depuis Grafana

Utilisation des fonctions natives de Grafana pour exporter les données des panels en CSV et les dashboards en JSON.

**Avantages :**
- Fonctionnalité native de Grafana.
- Aucune modification du code Python.
- Export rapide des métriques visualisées.
- Simplicité d'utilisation pour une analyse ponctuelle.

**Inconvénients :**
- Manipulations manuelles répétitives.
- Risque d'erreur humaine.
- Dépendance aux requêtes, transformations et paramètres des dashboards.
- Corrélation avec les résultats k6 à effectuer séparément.
- Absence d'automatisation complète des campagnes et répétitions.
- Ne permet pas de produire directement l'ensemble des fiches d'expérience.

**Conclusion :** solution intéressante pour une extraction ponctuelle, mais insuffisante comme mécanisme principal de sauvegarde des benchmarks.

### Option B – Centralisation complète dans Python avec l'API Prometheus

Faire évoluer le script Python afin qu'il interroge directement l'API HTTP de Prometheus et récupère les séries temporelles nécessaires aux analyses.

Les données sont ensuite converties et sauvegardées dans des fichiers CSV ou JSON.

**Avantages :**
- Automatisation des exports.
- Contrôle précis des périodes et de la résolution des mesures.
- Possibilité de corréler les métriques d'infrastructure avec les résultats k6.
- Génération de tableaux de synthèse.
- Indépendance vis-à-vis de l'interface Grafana.
- Réutilisation du script Python existant.

**Inconvénients :**
- Maintenance du code Python.
- Gestion des erreurs API et des timestamps.
- Maintenance des requêtes PromQL.
- Nécessité de normaliser les formats de sortie.
- Dépendance à la disponibilité et à la rétention des données Prometheus.

**Conclusion :** solution adaptée à l'automatisation, mais qui ne doit pas remplacer Grafana pour la visualisation.

### Option C – Utilisation exclusive des exports natifs de k6

Utilisation des fonctionnalités d'export de k6 pour sauvegarder les résultats des tests de charge, sans centralisation complémentaire dans Python.

**Avantages :**
- Exports produits directement par le générateur de charge.
- Récupération des indicateurs de latence, débit et erreurs.
- Automatisation native des résultats de test.
- Réduction du développement d'outils d'analyse spécifiques.

**Inconvénients :**
- Ne couvre pas à lui seul les métriques détaillées de Kubernetes.
- Nécessite un mécanisme indépendant pour collecter les ressources CPU, mémoire et réplicas.
- Corrélation entre données de charge et données Prometheus à réaliser séparément.
- Synthèse comparative des répétitions à construire.

**Conclusion :** solution utile pour la collecte des résultats de charge, mais insuffisante pour répondre à l'ensemble des besoins P5.

### Option D – Architecture hybride Python / Prometheus / Grafana / k6

Conserver chaque outil selon sa responsabilité :

- k6 produit les résultats des tests de charge.
- Prometheus collecte les métriques de l'infrastructure.
- Python centralise les résultats, interroge Prometheus, réalise les agrégations et produit les fichiers d'analyse.
- Grafana permet de visualiser et d'explorer les métriques.
- Git conserve les scripts, dashboards, configurations et résultats nécessaires à la reproductibilité.

Le script Python actuel (`analyze.py`) est conservé comme base de cette architecture.

Ses capacités d'analyse et d'export sont maintenues. Les besoins complémentaires pourront être traités par évolutions ciblées, notamment la sauvegarde des séries Prometheus et l'enrichissement des métadonnées.

**Avantages :**
- Réutilisation du travail déjà réalisé.
- Séparation claire des responsabilités.
- Automatisation de l'analyse.
- Corrélation entre performances applicatives et ressources Kubernetes.
- Conservation des capacités de visualisation de Grafana.
- Possibilité de faire évoluer progressivement la chaîne.
- Bonne adéquation avec les livrables attendus.

**Inconvénients :**
- Plusieurs composants à maintenir.
- Nécessité de définir un format commun pour les résultats.
- Synchronisation temporelle indispensable.
- Développement complémentaire nécessaire pour couvrir tous les indicateurs et scénarios.

**Conclusion :** cette solution offre le meilleur compromis entre automatisation, reproductibilité, lisibilité et réutilisation de l'existant.

## 4. Décision proposée

**Retenir l'option D : architecture hybride Python / Prometheus / Grafana / k6.**

Le script Python existant est conservé comme outil central d'analyse et d'agrégation des résultats.

Il ne sera pas remplacé par les fonctions d'export de Grafana.

Les responsabilités sont définies comme suit :

| Composant | Responsabilité |
|---|---|
| k6 | Exécution des benchmarks et production des résultats de charge |
| Prometheus | Collecte des métriques de l'infrastructure Kubernetes |
| Python | Analyse, agrégation, interrogation Prometheus et génération des exports |
| Grafana | Visualisation, exploration et export ponctuel des métriques |
| Git | Versionnement des scripts, dashboards et résultats d'expérimentation |

Les exports natifs de Grafana restent disponibles pour les analyses ponctuelles et les vérifications.

Les dashboards sont exportés en JSON et conservés dans le dépôt Git.

Les résultats des campagnes sont conservés dans des fichiers structurés, en distinguant les données issues du générateur de charge, les métriques d'infrastructure et les résultats agrégés.

## 5. Conséquences de la décision

### Conséquences positives

- Conservation du script Python existant.
- Aucun remplacement de l'architecture actuelle.
- Réduction des manipulations manuelles.
- Possibilité de comparer plusieurs campagnes de benchmarks.
- Centralisation des résultats dans un format exploitable.
- Meilleure traçabilité des expérimentations.
- Réutilisation des dashboards Grafana.
- Facilité d'analyse pour le rapport final.

### Conséquences négatives et points de vigilance

- Maintenance du script Python.
- Dépendance à l'accessibilité de Prometheus lors de la collecte.
- Nécessité de synchroniser les horloges des machines.
- Gestion de la rétention des données Prometheus.
- Risque de perte de précision lorsque seules des métriques agrégées sont sauvegardées.
- Nécessité de documenter les versions, configurations et conditions expérimentales.

## 6. Évolutions identifiées

Les évolutions suivantes sont identifiées pour améliorer la couverture des exigences P5. Elles ne constituent pas une modification immédiate du script existant.

1. Étudier l'archivage des séries temporelles Prometheus au format CSV.
2. Enrichir les métadonnées des expérimentations avec le commit Git, les versions et la configuration des ressources.
3. Étudier la génération automatique des fiches d'expérience.
4. Compléter les mesures spécifiques des scénarios B3, B4, B6 et B7.
5. Évaluer la nécessité de conserver les mesures individuelles des requêtes k6.
6. Harmoniser les fenêtres temporelles et la résolution de collecte Prometheus.
7. Étudier une validation bloquante lorsque le nombre minimal de répétitions n'est pas atteint.

## 7. Plan B

En cas de dysfonctionnement du collecteur Python ou d'indisponibilité de l'API Prometheus :

1. Conserver les résultats produits nativement par k6.
2. Utiliser Grafana pour récupérer manuellement les métriques disponibles.
3. Documenter précisément les heures de début et de fin de l'expérience.
4. Compléter manuellement la fiche d'expérience.
5. Conserver les résultats et signaler explicitement les données manquantes.

Cette procédure permet de poursuivre les campagnes de benchmark sans dépendre entièrement du script Python.

## 8. Critères de validation

La décision sera considérée comme validée lorsque :

- Les benchmarks peuvent être exécutés et leurs résultats archivés.
- Les répétitions sont conservées individuellement.
- Les résultats peuvent être agrégés avec médiane et dispersion.
- Les métriques Prometheus peuvent être associées temporellement aux exécutions k6.
- Les exports CSV sont exploitables indépendamment de Grafana.
- Les dashboards Grafana peuvent être exportés et réimportés depuis le dépôt Git.
- Les fiches d'expérience disposent des informations nécessaires à la reproductibilité.
- Un autre membre de l'équipe peut exploiter les résultats archivés.



**Statut final :** décision proposée, à valider après comparaison des besoins et vérification des exports sur une campagne réelle de benchmarks.
