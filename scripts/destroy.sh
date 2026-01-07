#!/usr/bin/env bash
set -euo pipefail

RG="${1:-rg-secure-web-lb-autoscale}"
az group delete -n "$RG" --yes --no-wait
