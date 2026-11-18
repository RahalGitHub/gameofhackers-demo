
#!/usr/bin/env bash
set -euo pipefail

# Reconstruction GameOfHackers DEMO uniquement
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TF_DIR="$ROOT/terraform"
ANSIBLE_DIR="$ROOT/ansible"
CONFIG="$ANSIBLE_DIR/files/cognito-config.js"

export AWS_PROFILE="x-streaming-lab"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_REGION="us-east-1"

EXPECTED_ACCOUNT="791925956830"

echo "=== GameOfHackers DEMO : reconstruction ==="

# 1. Vérifications de sécurité
for cmd in aws terraform npm node python3 ansible-playbook; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERREUR : commande manquante : $cmd"
    exit 1
  fi
done

test -f "$TF_DIR/main.tf"
test -f "$CONFIG"
test -f "$ROOT/vite.config.js"
test -f "$ANSIBLE_DIR/redeploy-gameofhackers.yml"

# Sécurité : interdire l'exécution sur le projet PROD
if [ "$(basename "$ROOT")" != "aws-video-streaming-automation - DEMO" ]; then
  echo "STOP : ce script doit être exécuté depuis le projet DEMO."
  exit 1
fi

if ! grep -qx 'domain: gameofhackers.fr' "$ANSIBLE_DIR/vars/generic.yaml"; then
  echo "STOP : domaine différent de gameofhackers.fr."
  exit 1
fi

ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"

if [ "$ACCOUNT" != "$EXPECTED_ACCOUNT" ]; then
  echo "STOP : mauvais compte AWS ($ACCOUNT)"
  exit 1
fi

echo "Compte AWS vérifié : $ACCOUNT"
echo "Région : $AWS_REGION"

# 2. Reconstruction Terraform
echo "=== Terraform apply ==="
terraform -chdir="$TF_DIR" apply

# 3. Récupération des identifiants Cognito
echo "=== Configuration Cognito ==="
POOL_ID="$(terraform -chdir="$TF_DIR" output -raw cognito_user_pool_id)"
CLIENT_ID="$(terraform -chdir="$TF_DIR" output -raw cognito_client_id)"

export POOL_ID CLIENT_ID CONFIG

python3 - <<'PY'
import os
import re
from pathlib import Path

path = Path(os.environ["CONFIG"])
content = path.read_text()

for key, value in (
    ("userPoolId", os.environ["POOL_ID"]),
    ("userPoolClientId", os.environ["CLIENT_ID"]),
):
    pattern = rf"(\b{key}\s*:\s*)[\"\x27][^\"\x27]*[\"\x27]"
    content, count = re.subn(
        pattern,
        lambda match: match.group(1) + '"' + value + '"',
        content,
    )
    if count != 1:
        raise SystemExit(f"ERREUR : {key} trouvé {count} fois")

path.write_text(content)
print("Configuration Cognito mise à jour.")
PY

# 3 bis. Recréation du compte utilisateur DEMO
echo "=== Création utilisateur Cognito DEMO ==="

DEMO_EMAIL="belka.r@icloud.com"

read -r -s -p "Mot de passe du compte DEMO : " DEMO_PASSWORD
echo

if [ -z "$DEMO_PASSWORD" ]; then
  echo "ERREUR : mot de passe vide."
  exit 1
fi

if aws cognito-idp admin-get-user --user-pool-id "$POOL_ID" --username "$DEMO_EMAIL" >/dev/null 2>&1; then
  echo "Utilisateur Cognito déjà présent."
else
  echo "Création du compte Cognito..."
  aws cognito-idp admin-create-user --user-pool-id "$POOL_ID" --username "$DEMO_EMAIL" --user-attributes Name=email,Value="$DEMO_EMAIL" Name=email_verified,Value=true --message-action SUPPRESS
fi

aws cognito-idp admin-set-user-password --user-pool-id "$POOL_ID" --username "$DEMO_EMAIL" --password "$DEMO_PASSWORD" --permanent

unset DEMO_PASSWORD
echo "Utilisateur DEMO prêt : $DEMO_EMAIL"

# 4. Construction du site Vite
echo "=== Vite build ==="
cd "$ROOT"
npm run build

# 5. Génération de l'inventaire
echo "=== Inventaire Ansible ==="
cd "$ANSIBLE_DIR"
bash ./generate-inventory.sh

# 6. Vérification des fichiers SSH
KEY="$TF_DIR/gameofhackers-vm-key.pem"

if [ ! -f "$KEY" ]; then
  echo "ERREUR : clé SSH introuvable : $KEY"
  exit 1
fi

chmod 600 "$KEY"

# 7. Déploiement complet
echo "=== Déploiement Ansible ==="
echo "=== Attente des EC2 (SSH) ==="
READY=0

for attempt in $(seq 1 30); do
  echo "Vérification SSH $attempt/30..."

  if ansible -i inventory.ini all -m ping -o; then
    READY=1
    break
  fi

  sleep 10
done

if [ "$READY" -ne 1 ]; then
  echo "ERREUR : les EC2 ne sont pas accessibles en SSH."
  exit 1
fi

echo "=== Déploiement Ansible ==="
ansible-playbook -i inventory.ini redeploy-gameofhackers.yml

echo "=== Vérification HTTPS ==="
curl --fail --silent --show-error --location \
  --max-time 30 \
  --output /dev/null \
  "https://gameofhackers.fr/login.html"

echo "=== RECONSTRUCTION DEMO TERMINÉE ==="
echo "Site : https://gameofhackers.fr"
echo "Cognito User Pool : $POOL_ID"
echo "Cognito Client ID : $CLIENT_ID"

