# ADR-002 : Mise en place des outils de surveillance
- Date : 23/10/2026
- Statut : proposée
## Contexte
Choix de Grafana et Prometheus pour la partie interfaces graphique et métrique

## Options considérées
Choix entre Grafana + Prometheus, Grafana + VictoriaMetrics, Grafana + Prometheus + Loki ou Grafana + VictoriaMetrics + Loki
## Décision
Pour le moment j'ai choisi de faire au plus simple donc Grafana + Prometheus.Pourquoi:Victoriametric permet de gérer de gros flux de données et est meilleur sur le plan du stockage de la donnée par rapport à Prometheus mais prometheus+ Grafana  en plus d’être une sorte de standard, est plus simple à installer. Le fait qu’il y ait déjà beaucoup de documentation, comme par exemple les guides de Stéphane Robert sur le duo, est un plus non négligeable.
Loki est un gestionnaire de logs que je compte mettre en place. Dans notre cas, pour le moment cela n’est pas utile, mais pour la sécurité de l’infrastructure, sa mise en place est prévue.
## Conséquences
On gagne en facilité de mise en place de l'infrastructure, mais on perd en capacité de gestion de gros flux de données (pour le moment puisque j'ai tout fait en local avec peu de machines, cela n'est pas grave). De même pour ce qui est du stockage, VictoriaMetric a un meilleur système de stockage, mais pour le moment ce n'est pas un problème.
## Plan B
On installe Grafana + VictoriaMetrics + Loki au lieu de Grafana + Prometheus + Loki.
