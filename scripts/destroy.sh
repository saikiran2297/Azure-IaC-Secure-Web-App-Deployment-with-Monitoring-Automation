#!/usr/bin/env bash
set -euo pipefail

RG="${1:-rg-secureweb-demo}"
echo "Deleting RG: $RG"
az group delete -n "$RG" --yes --no-wait
echo "Delete initiated."
