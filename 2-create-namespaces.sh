#!/bin/sh

export VAULT_ADDR=http://127.0.0.1:8200

vault login root

vault namespace create dev

export VAULT_NAMESPACE="dev"

vault namespace create app1

unset VAULT_NAMESPACE