#!/usr/bin/env bash
set -euo pipefail

RG="${1:-rg-secureweb-demo}"
LOC="${2:-uksouth}"

echo "Creating RG: $RG in $LOC"
az group create -n "$RG" -l "$LOC" -o table

echo "Deploying Bicep..."
az deployment group create \
  -g "$RG" \
  -f infra/main.bicep \
  -p @infra/main.parameters.json \
  -o table

echo "Done. Fetch outputs:"
az deployment group show -g "$RG" -n "$(az deployment group list -g "$RG" --query '[0].name' -o tsv)" --query properties.outputs -o jsonc

