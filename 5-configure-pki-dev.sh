#!/bin/sh

export VAULT_ADDR=http://127.0.0.1:8200
if [ ! -f "my_ip.txt" ]
then
  echo "Please set your local ip in a file called my_ip.txt"
  exit 1
fi

export EXTERNAL_VAULT_ADDR="http://$(cat my_ip.txt):8200"

vault login root

# Configure PKI intermediate CA on dev namespace

export VAULT_NAMESPACE=dev

vault secrets enable -path=pki_dev_int pki

vault write -format=json pki_dev_int/intermediate/generate/internal common_name="dev.colin.testing Intermediate Authority" ttl=150m | jq -r ".data.csr" > pki_dev_int.csr

unset VAULT_NAMESPACE

vault write -format=json pki/root/sign-intermediate csr=@pki_dev_int.csr format=pem_bundle ttl=149m | jq -r ".data.certificate" > signed_certificate_dev.pem

cat signed_certificate_dev.pem signed_certificate_root.pem > signed_certificate_dev_root.pem

export VAULT_NAMESPACE=dev

vault write pki_dev_int/intermediate/set-signed certificate=@signed_certificate_dev_root.pem

vault write pki_dev_int/config/urls \
  issuing_certificates="${EXTERNAL_VAULT_ADDR}/v1/dev/pki_dev_int/ca" \
  crl_distribution_points="${EXTERNAL_VAULT_ADDR}/v1/dev/pki_dev_int/crl"