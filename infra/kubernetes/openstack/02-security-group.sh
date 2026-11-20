#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-variables.sh"

openstack security group create "$SG" --description "Kubernetes nodes - MLOps equipe 2"
openstack security group rule create "$SG" --ingress --protocol tcp --dst-port 22 --remote-ip "$ADMIN_CIDR"
openstack security group rule create "$SG" --ingress --protocol tcp --dst-port 6443 --remote-group "$SG"
openstack security group rule create "$SG" --ingress --protocol tcp --dst-port 6443 --remote-ip "$ADMIN_CIDR"
openstack security group rule create "$SG" --ingress --protocol tcp --dst-port 10250 --remote-group "$SG"
# etcd : un seul control plane, le groupe lui-même suffit
openstack security group rule create "$SG" --ingress --protocol tcp --dst-port 2379:2380 --remote-group "$SG"
# Flannel VXLAN
openstack security group rule create "$SG" --ingress --protocol udp --dst-port 8472 --remote-group "$SG"
# ICMP entre nœuds (debug, test MTU)
openstack security group rule create "$SG" --ingress --protocol icmp --remote-group "$SG"
# NodePort / ingress depuis le générateur de charge k6
openstack security group rule create "$SG" --ingress --protocol tcp --dst-port 30000:32767 --remote-ip "$K6_CIDR"
# (Option) ICMP depuis l'admin :
# openstack security group rule create "$SG" --ingress --protocol icmp --remote-ip "$ADMIN_CIDR"

openstack security group rule list "$SG" --long
