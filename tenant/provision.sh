#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

PROJECT=$3
USER_NAME=$1
USER_PASS=$2
EXT_NET=$4
IMAGE=debian-12
FLAVOR=k8s.small8
KEY=cluster-key
NET=net-cluster
SUBNET=subnet-cluster
ROUTER=router-cluster
SG=sg-cluster
NODES="node-1 node-2 node-3"

# --- Admin : projet, utilisateur, quotas ---
openstack project show $PROJECT >/dev/null 2>&1 || openstack project create $PROJECT
openstack user show $USER_NAME >/dev/null 2>&1 || \
  openstack user create --project $PROJECT --password "$USER_PASS" $USER_NAME
openstack role add --project $PROJECT --user $USER_NAME member
openstack quota set --instances 5 --cores 10 --ram 12288 \
  --volumes 5 --gigabytes 30 --snapshots 5 \
  --networks 5 --floating-ips 5 --secgroups 10 $PROJECT

# --- Passage en tenant ---
export OS_PROJECT_NAME=$PROJECT
export OS_USERNAME=$USER_NAME
export OS_PASSWORD=$USER_PASS
unset OS_PROJECT_ID OS_TENANT_ID OS_USER_DOMAIN_ID OS_PROJECT_DOMAIN_ID
export OS_USER_DOMAIN_NAME=Default OS_PROJECT_DOMAIN_NAME=Default

# --- Keypair ---
openstack keypair show $KEY >/dev/null 2>&1 || \
  openstack keypair create --public-key ~/.ssh/id_ed25519.pub $KEY

# --- R\Uffffffffau ---
openstack network show $NET >/dev/null 2>&1 || openstack network create $NET
openstack subnet show $SUBNET >/dev/null 2>&1 || \
  openstack subnet create --network $NET --subnet-range 10.10.0.0/24 \
    --dns-nameserver 1.1.1.1 --dns-nameserver 8.8.8.8 $SUBNET
openstack router show $ROUTER >/dev/null 2>&1 || {
  openstack router create $ROUTER
  openstack router set --external-gateway $EXT_NET $ROUTER
  openstack router add subnet $ROUTER $SUBNET
}

# --- Groupe de s\Uffffffffrit\Uffffffff--
if ! openstack security group show $SG >/dev/null 2>&1; then
  openstack security group create $SG
  openstack security group rule create --proto tcp --dst-port 22 $SG
  openstack security group rule create --proto icmp $SG
  openstack security group rule create --remote-group $SG --proto tcp $SG
  openstack security group rule create --remote-group $SG --proto udp $SG
  openstack security group rule create --remote-group $SG --proto icmp $SG
fi

# --- VMs + floating IPs ---
for n in $NODES; do
  openstack server show $n >/dev/null 2>&1 || \
    openstack server create --flavor $FLAVOR --image $IMAGE --key-name $KEY \
      --network $NET --security-group $SG --user-data cloud-init.yaml --wait $n
done

for n in $NODES; do
  if ! openstack server show $n -f value -c addresses | grep -q '192.168.200'; then
    FIP=$(openstack floating ip create $EXT_NET -f value -c floating_ip_address)
    openstack server add floating ip $n $FIP
  fi
done

# --- Volume + snapshot ---
openstack volume show data-node-1 >/dev/null 2>&1 || \
  openstack volume create --size 5 data-node-1
openstack volume snapshot show snap-data-node-1 >/dev/null 2>&1 || \
  openstack volume snapshot create --volume data-node-1 snap-data-node-1

echo "=== Inventaire ==="
openstack server list
openstack floating ip list
openstack volume list
