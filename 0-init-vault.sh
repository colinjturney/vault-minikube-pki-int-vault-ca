#!/bin/bash

if [ -f vault.pid ]; then
  echo "Vault PID file already exists"
  exit 1
fi

export VAULT_LOG_LEVEL=debug

vault server -dev -dev-root-token-id=root -dev-listen-address="0.0.0.0:8200" >./vault.log 2>&1 &

echo $! > vault.pid

sleep 5

echo "Vault started with PID:$(cat vault.pid)"

# Check if running Vault Enterprise

vault version | grep ent

if [ $? == 0 ]
then
  echo "Running Vault Enterprise, checking for license..."

  if [ ! -f license-vault.txt ]; then
    echo "No file called license-vault.txt found."
    echo "Please create a file called license-vault.txt that contains a valid Vault license key"
    echo "Exiting..."
    exit 1
  else

    export ROOT_TOKEN=root
    export LICENSE_KEY=$(cat license-vault.txt)

    cat<<EOF > license.json
{
  "text": "${LICENSE_KEY}"
}
EOF

    curl \
      -X PUT \
      --header "X-Vault-Token: ${ROOT_TOKEN}" \
      -d @license.json \
      http://127.0.0.1:8200/v1/sys/license

    # Confirm License Status

    curl \
        --header "X-Vault-Token: ${ROOT_TOKEN}" \
        http://127.0.0.1:8200/v1/sys/license | jq

  fi
fi
