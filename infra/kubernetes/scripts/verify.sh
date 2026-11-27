#!/usr/bin/env bash
# Recette rapide, à lancer sur le control plane.
set -u
echo "== Nœuds ==";             kubectl get nodes -o wide
echo "== Pods en erreur ==";    kubectl get pods -A --no-headers | grep -v -E "Running|Completed" || echo "OK : tout est Running"
echo "== StorageClass ==";      kubectl get sc
echo "== Metrics ==";           kubectl top nodes || echo "metrics-server pas encore prêt"
echo "== cert-manager ==";      kubectl get pods -n cert-manager; kubectl get clusterissuer
echo "== Namespaces/quotas =="; kubectl get ns mlops models monitoring; kubectl get resourcequota -A
echo "== MTU ==";               ip -o link show | grep -E "ens|eth|flannel" | awk '{print $2, $4, $5}'
echo "Test MTU inter-pods : kubectl run t --rm -it --image=busybox --restart=Never -- ping -M do -s 1372 <IP_POD_AUTRE_NOEUD>"
