#!/bin/sh

if [ ! -f "my_ip.txt" ]
then
  echo "Please set your local ip in a file called my_ip.txt"
  exit 1
fi

export LOCAL_IP=$(cat my_ip.txt)

# Get Vault Server IP
export EXTERNAL_VAULT_ADDR="http://${LOCAL_IP}:8200"
echo "EXTERNAL_VAULT_ADDR: ${EXTERNAL_VAULT_ADDR}"

# Set up service accounts
kubectl create namespace vault-demo
kubectl create serviceaccount vault-auth
kubectl create serviceaccount vault-agent-auth
kubectl apply -f configs/vault-service-accounts.yaml

# Label namespace to ensure Vault agent webhook works
kubectl label namespace default vault.hashicorp.com/agent-webhook=enabled

# Deploy Vault Agent Injector
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault hashicorp/vault \
  --set "global.openshift=true" \
  --set "injector.externalVaultAddr=${EXTERNAL_VAULT_ADDR}"
