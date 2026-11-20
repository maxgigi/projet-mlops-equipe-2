#!/usr/bin/env bash
set -euo pipefail
openstack flavor create --vcpus 4 --ram 6144 --disk 50 k8s-cp
openstack flavor create --vcpus 4 --ram 6144 --disk 100 k8s-worker
openstack flavor list --long
