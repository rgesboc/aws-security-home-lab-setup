#!/usr/bin/env bash
set -euo pipefail

aws organizations list-accounts \
  --query 'Accounts[].{Name:Name,Id:Id,Email:Email,Status:Status}' \
  --output table
