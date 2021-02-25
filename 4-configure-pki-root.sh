#!/bin/sh

export VAULT_ADDR=http://127.0.0.1:8200
if [ ! -f "my_ip.txt" ]
then
  echo "Please set your local ip in a file called my_ip.txt"
  exit 1
fi

export EXTERNAL_VAULT_ADDR="http://$(cat my_ip.txt):8200"

unset VAULT_NAMESPACE

vault login root

vault secrets enable pki

vault secrets tune -max-lease-ttl=20m pki

# Configure self-signed root CA on PKI secrets engine mounted on root namespace

vault write -format=json pki/root/generate/internal \
  common_name=colin.testing \
  ttl=200m | jq -r ".data.certificate" > signed_certificate_root.pem

vault write pki/config/urls \
  issuing_certificates="${EXTERNAL_VAULT_ADDR}/v1/pki/ca" \
  crl_distribution_points="${EXTERNAL_VAULT_ADDR}/v1/pki/crl"