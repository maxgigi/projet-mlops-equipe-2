# ADR-11 – Révision des indicateurs, seuils et alertes de l'observabilité

- **Date :** 27/11/2026
- **Statut :** Proposée
- **Périmètre :** Prometheus, Grafana, métriques Kubernetes et alertes
- **Décision proposée :** Normalisation des indicateurs et refonte progressive des règles d'alerte selon leur criticité.
- **Cette ADR est sujette à une possible révision dans le futur :** Cette réflexion a été faite et construite sur la base des résultats obtenus avec des machines locales similaires à celles mises en place lors du projet, mais l'infrastructure réelle peut donner des résultats différents et mener à des reprises de cette réflexion.

---

## 1. Contexte

L'environnement utilise Prometheus pour collecter les métriques et Grafana pour les visualiser et configurer les alertes.

Les dashboards présentent notamment :
- L'utilisation CPU.
- La consommation mémoire.
- Le nombre de réplicas.
- La latence de l'API d'inférence.
- Les performances pendant les tests de charge.

Des alertes ont également été configurées afin de détecter :
- La disparition de tous les réplicas.
- Une utilisation CPU supérieure à 50 %.
- Une consommation mémoire proche de la limite.
- D'autres situations susceptibles de signaler une dégradation de la plateforme.

Cependant, plusieurs observations conduisent à remettre en question la pertinence des seuils actuels.

### 1.1 Constats

Pendant les benchmarks, l'utilisation CPU atteint régulièrement environ 50 %, tandis qu'en dehors des tests elle reste généralement inférieure à 1 %.

L'alerte CPU est donc fréquemment déclenchée pendant les expérimentations.

Ce comportement n'est pas nécessairement anormal : une augmentation de la consommation CPU est attendue lors de la génération de charge.

En revanche, le déclenchement fréquent de cette alerte ne permet pas de déterminer à lui seul si le seuil choisi est pertinent.

D'autres alertes, notamment celles concernant la mémoire ou la disponibilité des réplicas, sont beaucoup moins souvent déclenchées.

Leur faible fréquence ne garantit toutefois pas leur efficacité : il est nécessaire de vérifier qu'elles détectent effectivement les situations problématiques.

### 1.2 Problématique

Deux questions principales sont soulevées :

1. Les indicateurs actuellement affichés dans Grafana représentent-ils correctement l'état des ressources et leur niveau de saturation ?
2. Les règles d'alerte permettent-elles de détecter les dégradations importantes sans produire un nombre excessif de fausses alertes ?

L'objectif est de définir une politique d'observabilité cohérente avec l'architecture et les scénarios de benchmarks du projet.

---

## 2. Besoins et contraintes du projet

Le cahier des charges définit plusieurs exigences liées à l'observabilité.

| Référence | Exigence |
|---|---|
| OBS-1 | Observation minimale : metrics-server, kubectl top, logs et journal des expériences |
| OBS-2 | Prometheus + Grafana : dashboards CPU, mémoire, réplicas et latence |
| OBS-3 | Benchmarks B1, B2, B4 et B5 avec au moins trois répétitions et analyse |
| OBS-4 | Observabilité avancée : métriques applicatives et alertes ; benchmarks B3 et B6 |

Les besoins propres aux benchmarks doivent également être pris en compte :

- B1 : disposer d'une mesure de référence de la latence et des erreurs.
- B2 : observer l'évolution CPU/RAM et du débit pendant la montée en charge.
- B3 : observer l'effet des limites CPU et le throttling.
- B4 : observer le scale-to-zero et le cold start.
- B5 : observer la montée et la descente du nombre de réplicas.
- B6 : observer les besoins en mémoire et les performances d'un modèle avancé.

La plateforme doit donc permettre de distinguer :
- Un comportement normal.
- Une utilisation élevée mais acceptable des ressources.
- Un risque de saturation.
- Une dégradation réelle du service.
- Une panne ou une indisponibilité.

Les alertes ne doivent pas empêcher les benchmarks de produire volontairement une charge importante.

---

## 3. Problèmes identifiés

### 3.1 Seuils CPU potentiellement trop sensibles

Le seuil actuel de 50 % déclenche régulièrement une alerte pendant les tests de charge.

Ce seuil pourrait être trop sensible, notamment si l'indicateur correspond à une utilisation relative à la limite CPU du conteneur.

Une consommation CPU élevée n'est pas automatiquement synonyme de problème.

Il faut notamment distinguer :
- L'utilisation CPU réelle.
- L'utilisation par rapport à la limite configurée.
- L'utilisation par rapport à la ressource demandée.
- Le CPU throttling. (Le CPU est limité à cause d'une interruption du côté du noyau Linux)

L'utilisation CPU doit être interprétée en fonction des ressources allouées à chaque conteneur et de la dégradation éventuelle des performances applicatives.

### 3.2 Interprétation de la mémoire

Une consommation mémoire proche de la limite représente un risque plus important qu'une simple hausse de consommation CPU.

Les limites mémoire Kubernetes peuvent provoquer des arrêts de processus par OOMKill lorsque le système doit traiter un dépassement de mémoire.

Il est donc nécessaire de distinguer :
- La mémoire réellement utilisée.
- La mémoire disponible par rapport à la limite.
- Les événements OOMKill.
- La mémoire totale du nœud.

Une alerte mémoire doit prendre en compte la durée du dépassement et la proximité de la limite.

### 3.3 Disponibilité des réplicas

La disparition de tous les réplicas alors que le service est censé fonctionner constitue un événement critique.

Cependant, dans le cas de Knative Serverless, le scale-to-zero est un comportement attendu et ne doit pas être interprété comme une panne.

La règle doit donc tenir compte du nombre de réplicas attendus et du mode de déploiement.

### 3.4 Absence de distinction entre les niveaux de criticité

Les seuils actuels ne semblent pas distinguer suffisamment :
- Les alertes informatives.
- Les risques de dégradation.
- Les situations critiques.

Cela peut rendre les alertes difficiles à interpréter et entraîner une fatigue liée aux notifications répétitives.

### 3.5 Efficacité des alertes non vérifiée

Une règle d'alerte qui se déclenche rarement n'est pas nécessairement inutile.

Inversement, une alerte fréquente n'est pas nécessairement pertinente.

L'efficacité des règles doit être mesurée par des tests contrôlés permettant de vérifier :
- Leur capacité à détecter une anomalie.
- Leur temps de détection.
- Leur capacité à retrouver un état normal.
- Leur résistance aux variations temporaires.
- Le nombre de faux positifs.

---

## 4. Options considérées

### Option A – Conserver les seuils actuels

Conserver les requêtes, les seuils et les règles d'alerte sans modification.

**Avantages :**
- Aucun travail supplémentaire.
- Aucun risque de modifier une règle qui détecte actuellement certaines situations.
- Les alertes existantes restent opérationnelles.

**Inconvénients :**
- Risque de notifications répétitives pendant les benchmarks.
- Les indicateurs peuvent être mal interprétés si leur normalisation est incorrecte.
- Absence de distinction claire entre comportement attendu et situation critique.
- Efficacité réelle des alertes non démontrée.

**Conclusion :**

Cette solution est simple, mais ne répond pas suffisamment aux problèmes identifiés.

### Option B – Augmenter les seuils numériques

Augmenter directement les seuils actuels, par exemple faire passer l'alerte CPU de 50 % à 70 % ou 80 %.

**Avantages :**
- Mise en œuvre simple.
- Réduction possible du nombre d'alertes CPU.
- Peu de modifications techniques.

**Inconvénients :**
- Le problème de définition de la métrique reste présent.
- Un seuil plus élevé peut masquer une saturation réelle.
- Le choix du nouveau seuil risque de reposer sur des observations insuffisantes.
- Une valeur identique ne convient pas nécessairement à tous les conteneurs.

**Conclusion :**

Cette approche peut faire partie d'une évolution, mais ne doit pas constituer la décision principale.

Il est nécessaire de vérifier la signification des pourcentages avant de modifier les seuils.

### Option C – Normaliser les indicateurs et revoir les seuils

Revoir les requêtes PromQL et les indicateurs utilisés dans les dashboards.

L'objectif est de présenter des mesures compréhensibles et comparables, notamment en fonction des ressources CPU et mémoire configurées.

Exemples :

- CPU utilisé en cœurs.
- CPU utilisé en pourcentage de la limite configurée.
- CPU throttling.
- Mémoire utilisée en octets.
- Mémoire utilisée en pourcentage de la limite.
- Réplicas désirés et réplicas disponibles.
- Latence p95 et taux d'erreur.

Les seuils visuels de Grafana seraient ensuite adaptés à ces indicateurs.

**Avantages :**
- Meilleure interprétation des métriques.
- Comparaison plus pertinente entre les workloads.
- Détection plus précise des situations proches de la saturation.
- Possibilité de conserver plusieurs indicateurs complémentaires.
- Cohérence accrue entre les dashboards.

**Inconvénients :**
- Nécessité de vérifier les métriques réellement exposées.
- Requêtes PromQL plus complexes.
- Modification de certains dashboards existants.
- Nécessité de documenter les unités et les méthodes de calcul.

**Conclusion :**

Cette solution est pertinente pour corriger les éventuels problèmes de normalisation et améliorer la compréhension des ressources.

### Option D – Revoir les règles d'alerte selon la criticité et la durée

Conserver les indicateurs, mais faire évoluer les règles d'alerte en fonction des risques réellement identifiés.

Les alertes seraient classées en trois niveaux :

- **Critical :** panne, indisponibilité ou risque immédiat pour le service.
- **Warning :** dégradation potentielle ou risque de saturation.
- **Info :** comportement notable à surveiller sans intervention immédiate.

Les règles prendraient également en compte la durée du dépassement.

Un dépassement ponctuel ne déclencherait pas nécessairement une notification.

**Avantages :**
- Réduction des fausses alertes.
- Meilleure hiérarchisation des événements.
- Meilleure lisibilité des notifications.
- Prise en compte des comportements normaux pendant les benchmarks.
- Possibilité de tester chaque règle indépendamment.

**Inconvénients :**
- Nécessité de définir des durées et seuils cohérents.
- Configuration des règles plus complexe.
- Risque de détection tardive si les durées sont excessives.
- Nécessité de tester les transitions entre états.

**Conclusion :**

Cette solution améliore la pertinence des alertes, mais doit s'appuyer sur des indicateurs correctement définis.

### Option E – Utiliser des seuils dynamiques ou adaptatifs

Définir les seuils à partir du comportement habituel de la plateforme, plutôt que d'utiliser uniquement des valeurs fixes.

Exemples :
- Comparer la consommation CPU à une référence en fonctionnement normal.
- Détecter une hausse inhabituelle de mémoire.
- Comparer les performances à une campagne de benchmark de référence.
- Détecter une dérive de latence par rapport à une baseline.

**Avantages :**
- Adaptation à des workloads différents.
- Détection possible de comportements inhabituels.
- Réduction de la dépendance à des valeurs statiques.
- Possibilité d'améliorer la détection sur le long terme.

**Inconvénients :**
- Complexité de mise en œuvre.
- Besoin d'historique et de références fiables.
- Risque de considérer progressivement une dégradation comme normale.
- Risque de faux positifs liés à la variabilité des expériences.
- Surdimensionnement potentiel de la solution pour un projet de cette taille.

**Conclusion :**

Cette solution peut constituer une amélioration future, mais n'est pas prioritaire.

---

## 5. Décision proposée

**Retenir une approche combinant les options C et D : normalisation des indicateurs et refonte des alertes selon leur criticité.**

Les seuils ne doivent pas être augmentés arbitrairement pour réduire les notifications.

La priorité est de définir correctement les indicateurs, puis de configurer les règles d'alerte en fonction des conséquences réelles sur le système.

Les seuils numériques proposés dans cette ADR constituent des hypothèses à valider expérimentalement, et non des valeurs définitives.

### 5.1 Révision des indicateurs Grafana

Les dashboards doivent distinguer les valeurs absolues et relatives.

| Ressource | Indicateurs recommandés |
|---|---|
| CPU | Utilisation en cœurs |
| CPU | Utilisation en % de la limite configurée |
| CPU | CPU throttling |
| Mémoire | Utilisation en MiB/GiB |
| Mémoire | Utilisation en % de la limite |
| Mémoire | Nombre d'OOMKills |
| Réplicas | Nombre désiré |
| Réplicas | Nombre disponible |
| Application | Latence p50/p95/p99 |
| Application | Taux d'erreur |
| Application | Débit en requêtes/seconde |

Les panneaux Grafana doivent également préciser les unités et les fenêtres temporelles utilisées.

Les pourcentages ne doivent pas être présentés sans préciser leur référence de calcul.

En particulier :
- Le CPU par rapport à la limite ne doit pas être confondu avec le CPU par rapport à la capacité du nœud.
- Le CPU request ne doit pas être interprété comme un plafond d'utilisation.
- La mémoire par rapport à la limite doit être distinguée de la mémoire consommée sur le nœud.

Lorsque cela est pertinent, des recording rules Prometheus pourront être utilisées pour centraliser les calculs des indicateurs normalisés et les réutiliser dans plusieurs dashboards et règles d'alerte.

### 5.2 Seuils visuels proposés pour les dashboards

Ces seuils sont des valeurs initiales à tester sur les workloads du projet.

| Indicateur | Normal | Surveillance | Niveau élevé |
|---|---:|---:|---:|
| CPU / limite CPU | Inférieur à 70 % | 70–85 % | Supérieur à 85 % |
| Mémoire / limite mémoire | Inférieur à 85 % | 85–95 % | Supérieur à 95 % |

Ces couleurs servent à faciliter la lecture des graphiques.

Elles ne constituent pas automatiquement des conditions d'alerte.

Pour les CPU sans limite configurée, le pourcentage d'utilisation par rapport à une limite ne doit pas être calculé artificiellement.

Pour les workloads importants, il est recommandé d'afficher également les métriques individuelles des conteneurs afin de ne pas masquer la saturation d'un conteneur derrière une moyenne de plusieurs pods.

### 5.3 Nouvelle politique d'alerte

Les alertes sont organisées par criticité.

| Alerte | Condition envisagée | Durée indicative | Priorité |
|---|---|---|---|
| Aucun réplica disponible | 0 réplica disponible alors qu'au moins 1 est attendu | 1 min | Critical |
| Réplicas insuffisants | Réplicas disponibles inférieurs aux réplicas désirés | 5 min | Warning |
| CPU élevé | Plus de 80 % de la limite CPU et saturation ou throttling significatif | 10 min | Warning |
| CPU fortement saturé | Plus de 90 % de la limite avec throttling et dégradation du service | 5 min | Critical |
| Mémoire élevée | Plus de 85 % de la limite mémoire | 5 min | Warning |
| Mémoire critique | Plus de 95 % de la limite mémoire | 2 min | Critical |
| OOMKill | Augmentation du nombre de conteneurs arrêtés par manque de mémoire | Détection | Critical |
| Latence élevée | Latence p95 supérieure à l'objectif défini | À définir | Warning / Critical |
| Taux d'erreur élevé | Taux d'erreur supérieur à l'objectif défini | À définir | Warning / Critical |
| Prometheus indisponible | Cible de collecte indisponible durablement | 2 min | Warning |

Les seuils CPU et mémoire constituent des points de départ expérimentaux.

Les durées et combinaisons de conditions doivent être validées en fonction du comportement réel de la plateforme.

Pour une alerte CPU, une consommation élevée isolée ne doit pas nécessairement provoquer une notification critique. Il est préférable de rechercher également des signes de saturation, comme le throttling CPU ou une dégradation de la latence.

Pour les alertes mémoire, l'augmentation des événements OOMKill doit être prise en compte indépendamment du seul pourcentage de mémoire utilisé.

Les alertes concernant la latence et les erreurs doivent s'appuyer sur des objectifs de service documentés. Le cahier des charges ne fixe pas de SLO numérique précis pour ces mesures.

### 5.4 Gestion du scale-to-zero

Le comportement Serverless doit être explicitement pris en compte.

Un service Knative configuré avec `minReplicas: 0` peut légitimement ne posséder aucun réplica lorsqu'il n'y a pas de trafic.

La règle « aucun réplica disponible » ne doit donc pas déclencher une alerte critique dans cette situation.

L'alerte doit vérifier :
- Le nombre de réplicas attendu.
- Le nombre de réplicas effectivement disponibles.
- Le mode de déploiement.
- L'état de disponibilité du service.

Une absence de réplica n'est critique que lorsque le service est censé être disponible.

Une indisponibilité réelle de l'API reste cependant critique, y compris si un mécanisme de scale-to-zero est configuré.

### 5.5 Gestion des benchmarks et des alertes

Les tests B2, B3, B5 et B6 peuvent provoquer volontairement une augmentation des ressources consommées.

Il est donc nécessaire de distinguer :
- Une utilisation élevée attendue pendant un benchmark.
- Une saturation accompagnée d'une dégradation réelle.
- Une panne ou indisponibilité du service.

Les alertes informatives et les alertes de ressources peuvent être identifiées avec des labels indiquant l'environnement, le namespace, le service et éventuellement le scénario expérimental.

Une politique de notification distincte pourra être utilisée pour les campagnes de benchmark.

Toutefois, les alertes critiques d'indisponibilité, de perte de service ou d'OOMKill ne doivent pas être désactivées automatiquement pendant une expérimentation.

---

## 6. Conséquences de la décision

### Conséquences positives

- Indicateurs plus compréhensibles.
- Seuils mieux adaptés aux ressources réellement allouées.
- Réduction des notifications non pertinentes.
- Meilleure distinction entre charge normale et saturation.
- Détection plus fiable des pannes.
- Prise en compte du comportement Serverless.
- Meilleure exploitation des résultats des benchmarks.
- Possibilité de comparer les comportements observés à des références expérimentales.

### Conséquences négatives et points de vigilance

- Modification des requêtes PromQL existantes.
- Modification des dashboards Grafana.
- Nécessité de vérifier la disponibilité des métriques de throttling et d'OOMKill.
- Nécessité de définir les objectifs de latence et d'erreurs.
- Risque de retarder une alerte si les durées sont trop longues.
- Risque de masquer des incidents si les seuils sont trop élevés.
- Nécessité de tester les règles dans plusieurs configurations.

### Conséquence sur les benchmarks

Les benchmarks doivent également servir à évaluer la pertinence des seuils et des alertes.

Les expérimentations B2 et B3 permettent notamment de vérifier à partir de quel niveau de charge une saturation apparaît.

Le benchmark B5 permet de vérifier que la montée et la descente des réplicas sont correctement interprétées.

Les résultats doivent permettre d'expliquer pourquoi une alerte s'est déclenchée, ou pourquoi elle aurait dû se déclencher.

---

## 7. Plan de validation

La nouvelle politique doit être validée par des tests contrôlés.

### Test 1 – Fonctionnement normal

Exécuter l'application sans générateur de charge.

Vérifier :
- CPU faible.
- Mémoire stable.
- Nombre de réplicas conforme au mode de déploiement.
- Absence d'alertes critiques injustifiées.

### Test 2 – Montée en charge (B2)

Augmenter progressivement le nombre de clients.

Vérifier :
- L'évolution des indicateurs CPU et mémoire.
- Le comportement des seuils visuels Grafana.
- La pertinence de l'alerte CPU.
- L'apparition éventuelle de throttling.
- L'évolution de la latence.

### Test 3 – Limites CPU (B3)

Tester plusieurs limites CPU : 0,25 / 0,5 / 1 / 2.

Vérifier :
- La consommation CPU en valeur absolue.
- Le pourcentage de la limite CPU.
- Le CPU throttling.
- La dégradation éventuelle de la latence.
- Le moment auquel l'alerte doit passer en Warning ou Critical.

### Test 4 – Pression mémoire

Dans un namespace de test isolé, provoquer une augmentation contrôlée de la consommation mémoire.

Vérifier :
- Le seuil Warning.
- Le seuil Critical.
- La détection des OOMKills.
- Le comportement lors du retour à un état normal.

### Test 5 – Disponibilité des réplicas

Tester séparément :
- Un fonctionnement normal avec plusieurs réplicas.
- La perte d'un réplica.
- La perte de tous les réplicas alors qu'ils sont attendus.
- Une mise à zéro volontaire avec Knative.

Vérifier que les alertes correspondent à la situation réelle.

### Test 6 – Indisponibilité de la collecte

Simuler l'indisponibilité d'une cible Prometheus ou une absence de données.

Vérifier que la perte de télémétrie n'est pas confondue avec une consommation CPU ou mémoire nulle.

### Critères de validation

La décision sera considérée comme validée lorsque :

- Chaque indicateur possède une définition et une unité documentées.
- Les pourcentages CPU et mémoire utilisent une référence de calcul explicite.
- Les seuils visuels sont cohérents avec les valeurs affichées.
- Les alertes possèdent un niveau de criticité.
- Les durées de déclenchement sont documentées.
- Les alertes critiques sont testées avec des incidents contrôlés.
- Le scale-to-zero ne déclenche pas de fausse alerte de panne.
- Les comportements attendus pendant les benchmarks sont distingués des dégradations réelles.
- Les alertes récupèrent correctement leur état normal après résolution.
- Les dashboards et les règles sont exportés et versionnés dans Git.

---

## 8. Plan B

En cas de résultats non satisfaisants après modification :

1. Conserver une copie des dashboards et des règles initiales.
2. Restaurer les seuils précédents.
3. Désactiver uniquement les nouvelles règles non validées.
4. Conserver les alertes critiques déjà éprouvées.
5. Analyser les résultats des expérimentations avant de proposer de nouveaux seuils.

Les modifications doivent être réalisées progressivement afin de ne pas perdre la capacité de détection existante.


**Statut final :** décision proposée, à valider après analyse des métriques actuelles, définition des objectifs de service et exécution des tests de validation.
