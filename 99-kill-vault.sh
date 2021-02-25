if [ ! -f vault.pid ]; then
  echo "Vault not running"
  exit 1
fi

kill -9 $(cat vault.pid)

echo "Killed Vault (PID:$(cat vault.pid))"

rm vault.pid vault.log

unset VAULT_NAMESPACE

helm delete vault