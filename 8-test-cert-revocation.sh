#!/bin/sh

function fetch_cert_and_crl() {
    # Source the actual issued certificate
    openssl s_client -connect www.ms-1.app1.dev.colin.testing:443 -servername www.ms-1.app1.dev.colin.testing 2>&1 < /dev/null | sed -n '/-----BEGIN/,/-----END/p' > ms-1.pem

    # Source the CRL and convert from DER to PEM
    CRL_URL=$(openssl x509 -noout -text -in ms-1.pem | grep -A 4 'X509v3 CRL Distribution Points' | grep URI | cut -f2- -d':')
    curl ${CRL_URL} -o crl.der
    openssl crl -inform DER -in crl.der -outform PEM -out crl.pem
}

fetch_cert_and_crl

# Get the CA Certificate Chain from Root to Intermediate CA

rm -f chain.pem

OLDIFS=$IFS; IFS=':' certificates=$(openssl s_client -connect www.ms-1.app1.dev.colin.testing:443 -servername www.ms-1.app1.dev.colin.testing -showcerts -tlsextdebug -tls1 -CAfile signed_certificate_app1.pem 2>&1 </dev/null | gsed -n '/-----BEGIN/,/-----END/ {/-----BEGIN/ s/^/:/; p}'); for certificate in ${certificates#:}; do echo $certificate | tee -a chain.pem; done; IFS=$OLDIFS

cat chain.pem crl.pem > crl_chain.pem

echo "Verifying validity of ms-1 cert against the CRL prior to revocation..."

openssl verify -crl_check -CAfile crl_chain.pem ms-1.pem

# Revoke the existing certificate

echo "Now attempting to revoke the current ms-1 cert and move it to ms-1-old.pem..."

SERIAL_NUMBER=$(openssl x509 -noout -serial -in ms-1.pem | cut -d'=' -f2 | sed 's/../&-/g;s/-$//')

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_NAMESPACE="dev/app1"

vault login root

echo "Attempting to revoke certificate with serial number ${SERIAL_NUMBER}..."
vault write pki_app1_int/revoke serial_number=${SERIAL_NUMBER}

mv ms-1.pem ms-1-old.pem

# Refetch the CRL and new cert
fetch_cert_and_crl

# Compare CRL against old cert
echo "Verifying validity of old cert that we have just revoked..."
openssl verify -crl_check -CAfile crl_chain.pem ms-1-old.pem

# Compare CRL against new cert
echo "Verifying validity of new cert that should have been requested by Vault Agent after revocation of old cert..."
openssl verify -crl_check -CAfile crl_chain.pem ms-1.pem
