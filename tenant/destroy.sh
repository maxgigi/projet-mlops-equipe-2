#!/bin/bash
set -uo pipefail
PROJECT=$3 
USER_NAME=$1
USER_PASS=$2

export OS_PROJECT_NAME=$PROJECT OS_USERNAME=$USER_NAME OS_PASSWORD=$USER_PASS
unset OS_PROJECT_ID OS_TENANT_ID OS_USER_DOMAIN_ID OS_PROJECT_DOMAIN_ID
export OS_USER_DOMAIN_NAME=Default OS_PROJECT_DOMAIN_NAME=Default

for n in node-1 node-2 node-3; do openstack server delete --wait $n; done
openstack floating ip list -f value -c ID | xargs -r -n1 openstack floating ip delete
openstack volume snapshot delete snap-data-node-1
openstack volume delete data-node-1
openstack router remove subnet router-cluster subnet-cluster
openstack router unset --external-gateway router-cluster
openstack router delete router-cluster
openstack subnet delete subnet-cluster
openstack network delete net-cluster
openstack security group delete sg-cluster
openstack keypair delete cluster-key
