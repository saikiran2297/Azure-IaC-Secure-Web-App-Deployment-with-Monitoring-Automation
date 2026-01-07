#!/usr/bin/env bash
set -euo pipefail

RG="${1:-rg-secure-web-lb-autoscale}"
LOC="${2:-uksouth}"

az group create -n "$RG" -l "$LOC"

az deployment group create \
  -n main \
  -g "$RG" \
  -f infra/main.bicep \
  -p infra/main.parameters.json
