#!/usr/bin/env bash
rc=0
for f in main variables outputs; do [ -s terraform/modules/network/$f.tf ] && ! grep -q '^# TODO' terraform/modules/network/$f.tf || { echo "- ❌ terraform/modules/network/$f.tf is still the starter"; rc=1; }; done
[ $rc -eq 0 ] && echo "- ✅ the module files are written"
grep -q 'for_each *= *var.environments' terraform/main.tf && echo "- ✅ the module is called with for_each" || { echo "- ❌ call the module with for_each = var.environments"; rc=1; }
if git ls-files | grep -qE '\.tfstate|\.terraform/|\.tfvars$'; then echo "- ❌ state, .terraform/ or tfvars is committed"; rc=1; else echo "- ✅ no state or .terraform/ committed"; fi
grep -rEq 'AKIA[0-9A-Z]{16}' . --exclude-dir=.git --exclude=tfcheck.py && { echo "- ❌ an AWS access key is committed"; rc=1; } || echo "- ✅ no AWS access key committed"
grep -qE '^ALL CHECKS PASSED \(' SUBMISSION.md && echo "- ✅ SUBMISSION.md shows ALL CHECKS PASSED" || { echo "- ❌ paste the verify.sh output ('ALL CHECKS PASSED') into SUBMISSION.md"; rc=1; }
exit $rc
