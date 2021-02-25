#!/bin/sh

# Apply vault-agent demo configurations

kubectl apply -f configs/www-vault-agent-colin-testing.yaml

echo ""
echo "Open https://$(minikube ip):32443 in your browser"