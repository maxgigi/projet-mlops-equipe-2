# Projet MLOps – Équipe 2

## Pôles :
- P1 : Cloud Openstack - Etan DU & Max GIRARDOT
- P2 : Kubernetes - Nawal ICHENE & Najib HABLOUZ
- P3 : MLFlow - Dinh Huy NGUYEN & Gia Khanh NGUYEN
- P4 : Serving - Bechir HAJ BELGACEM & Yassir BENHADDOUCHE
- P5 : Observation et tests - Gregory CAVILLOT
- P6 : Intégration et documentation - Max GIRARDOT

## Structure du dépôt
- README.md # comment tout reconstruire de A a Z (OpenStack inclus)
- versions.yaml # versions figees (OpenStack, Kubernetes, KServe...)
- Makefile # make openstack | tenant | cluster | platform | train | deploy-model | bench | demo
- docs/ # architecture, adr/, rapport/, journal/ (carnets de bord)
- openstack/ # deploiement : MicroStack, DevStack ou Kolla-Ansible
- tenant/ # provisioning OpenStack : OpenTofu ou openstacksdk, cloud-init
- infra/kubernetes/ # playbooks Ansible ou scripts kubeadm/k3s
- platform/ # manifests ou Helm : minio, mlflow, kserve, knative, monitoring
- ml/ # src/, tests/, train.py, configuration MLflow
- serving/ # InferenceService, secrets (modeles sans valeurs), tests d’API
- bench/ # scripts k6/Locust, resultats bruts (CSV), notebooks
- .ci/ # pipeline (lint, validation des manifests, tests)

## Comment tout reconstruire de A à Z (OpenStack inclus)
TODO
