# ADR-006 : Flannel comme plugin réseau (CNI)

- Date : [23/10/2026]
- Statut : proposée

## Contexte
Le cluster tourne dans des VM OpenStack, dont le réseau de tenant est lui-même encapsulé (VXLAN/GRE). Un CNI qui encapsule à son tour réduit le MTU utile. Les points de vigilance MTU et groupes de sécurité ont déjà été identifiés dans le document d'architecture.

## Options considérées
| Option | Avantages | Inconvénients |
|---|---|---|
| Flannel | Très simple, léger, peu de ressources | Pas de NetworkPolicy native, fonctionnalités limitées |
| Calico | NetworkPolicy, mode sans encapsulation possible (BGP), très répandu | Plus complexe, plus de composants |
| Cilium | eBPF, observabilité, NetworkPolicy avancées | Prérequis noyau, plus lourd à maîtriser |

## Décision
Nous retenons **Flannel**. Raison principale : simplicité et faible consommation sur un cluster à ressources limitées. Version : [à compléter, à figer dans `versions.yaml`]. Backend : [à compléter, ex. VXLAN].

## Conséquences
- (+) Installation rapide, peu de ressources consommées.
- (−) Pas de NetworkPolicy : l'isolation entre pods repose sur autre chose (groupes de sécurité OpenStack, [à compléter]).
- (−) Double encapsulation : MTU des pods à calculer et à fixer (MTU du réseau OpenStack moins l'en-tête VXLAN, soit 50 octets). Valeur retenue : [à compléter].
- Validation actuelle : [à compléter]. **À rejouer sur OpenStack**.

## Plan B
Migrer vers Calico si les NetworkPolicy deviennent nécessaires ou si le MTU pose des problèmes persistants.
