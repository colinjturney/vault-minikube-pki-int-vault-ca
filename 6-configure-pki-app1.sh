#!/bin/sh

export VAULT_ADDR=http://127.0.0.1:8200
if [ ! -f "my_ip.txt" ]
then
  echo "Please set your local ip in a file called my_ip.txt"
  exit 1
fi

export EXTERNAL_VAULT_ADDR="http://$(cat my_ip.txt):8200"

vault login root

export VAULT_NAMESPACE=dev/app1/

vault secrets enable -path=pki_app1_int pki

vault write -format=json pki_app1_int/intermediate/generate/internal common_name="app1.dev.colin.testing Intermediate Authority" ttl=100m | jq -r ".data.csr" > pki_app1_int.csr

export VAULT_NAMESPACE=dev

vault write -format=json pki_dev_int/root/sign-intermediate csr=@pki_app1_int.csr format=pem_bundle ttl=99m  | jq -r ".data.certificate" > signed_certificate_app1.pem

export VAULT_NAMESPACE=dev/app1/

vault write pki_app1_int/intermediate/set-signed certificate=@signed_certificate_app1.pem

vault write pki_app1_int/config/urls \
  issuing_certificates="${EXTERNAL_VAULT_ADDR}/v1/dev/app1/pki_app1_int/ca" \
  crl_distribution_points="${EXTERNAL_VAULT_ADDR}/v1/dev/app1/pki_app1_int/crl"

# Configure a role on the pki_app1_int PKI secrets engine to issue certs from.

vault write pki_app1_int/roles/vault-agent \
    allowed_domains=ms-1.app1.dev.colin.testing \
    allow_bare_domains=true \
    allow_subdomains=false \
    max_ttl=10m \
    generate_lease=true \
