#!/usr/bin/env bash
# Destroys everything this lab created. Run with: ./teardown.sh
set -u
cd "$(dirname "$0")"
aws sts get-caller-identity >/dev/null 2>&1 || { echo "No working AWS credentials." >&2; exit 1; }
[ -d terraform/.terraform ] && terraform -chdir=terraform destroy -auto-approve -input=false
[ -d experiments/count-vs-for-each/.terraform ] && terraform -chdir=experiments/count-vs-for-each destroy -auto-approve -input=false >/dev/null 2>&1
rm -rf experiments/count-vs-for-each/.terraform experiments/count-vs-for-each/terraform.tfstate*
rm -f terraform/terraform.tfstate terraform/terraform.tfstate.backup
echo "Now run ./verify-teardown.sh"
