#!/bin/bash
set -euo pipefail

TF_DIR="../terraform"

WEB_PUBLIC_IP=$(terraform -chdir="$TF_DIR" output -raw web_elastic_ip)
WEB_PRIVATE_IP=$(terraform -chdir="$TF_DIR" output -raw web_private_ip)
BACKEND_PRIVATE_IP=$(terraform -chdir="$TF_DIR" output -raw streamer_private_ip)

cat > inventory.ini <<INVENTORY
[web]
frontend ansible_host=$WEB_PUBLIC_IP private_ip=$WEB_PRIVATE_IP

[web:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../terraform/gameofhackers-vm-key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new'

[streamer]
backend ansible_host=$BACKEND_PRIVATE_IP

[streamer:vars]
ansible_user=ubuntu
ansible_ssh_private_key_file=../terraform/gameofhackers-vm-key.pem
ansible_ssh_common_args='-o StrictHostKeyChecking=accept-new -o ProxyCommand="ssh -i ../terraform/gameofhackers-vm-key.pem -o StrictHostKeyChecking=accept-new -W %h:%p ubuntu@$WEB_PUBLIC_IP"'
INVENTORY

echo "Inventaire GameOfHackers généré."
echo "Frontend public : $WEB_PUBLIC_IP"
echo "Frontend privé  : $WEB_PRIVATE_IP"
echo "Backend privé   : $BACKEND_PRIVATE_IP"
