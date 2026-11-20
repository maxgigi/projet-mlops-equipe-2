#!/usr/bin/env bash
export OS_CLOUD="A_REMPLIR_P1_CLOUDS_YAML"      # ou : source openrc.sh
export IMG="A_REMPLIR_P1_IMAGE"                 # ex. ubuntu-24.04
export NET="A_REMPLIR_P1_RESEAU_TENANT"         # réseau 10.10.0.0/24
export EXT_NET="A_REMPLIR_P1_RESEAU_EXTERNE"    # pool des floating IP
export KEY="A_REMPLIR_KEYPAIR"
export SG="k8s-sg"
export ADMIN_CIDR="A_REMPLIR_ADMIN_CIDR"        # ex. 192.168.1.50/32
export K6_CIDR="A_REMPLIR_K6_CIDR"              # VM k6 hors OpenStack
export FLAVOR_CP="k8s-cp"                       # 2 vCPU / 6 Go / 40 Go
export FLAVOR_WORKER="k8s-worker"               # 4 vCPU / 6 Go / 50 Go
export COMPUTE_1=""                             # nom du compute 1 (admin seulement, sinon laisser vide)
export COMPUTE_2=""                             # nom du compute 2 (admin seulement, sinon laisser vide)