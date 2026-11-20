#!/usr/bin/env bash
# 1 control plane + 3 workers. Placement voulu : CP + W1 sur compute 1, W2 + W3 sur compute 2.
set -euo pipefail
source "$(dirname "$0")/00-variables.sh"
CI="$(dirname "$0")/../cloud-init.yaml"

az() { [ -n "${1:-}" ] && echo "--availability-zone nova:$1" || true; }

create() {  # nom flavor compute
  openstack server create --wait --flavor "$2" --image "$IMG" --network "$NET" \
    --security-group "$SG" --key-name "$KEY" --user-data "$CI" $(az "${3:-}") "$1"
}

create k8s-cp-1 "$FLAVOR_CP"     "$COMPUTE_1"
create k8s-w1   "$FLAVOR_WORKER" "$COMPUTE_1"
create k8s-w2   "$FLAVOR_WORKER" "$COMPUTE_2"
create k8s-w3   "$FLAVOR_WORKER" "$COMPUTE_2"

# Floating IP : au minimum sur le CP (SSH + API) ; workers pour les tests k6
for vm in k8s-cp-1 k8s-w1 k8s-w2 k8s-w3; do
  fip=$(openstack floating ip create "$EXT_NET" -f value -c floating_ip_address)
  openstack server add floating ip "$vm" "$fip"
  echo "$vm -> $fip"
done
openstack server list -c Name -c Status -c Networks
