#!/usr/bin/env bash
# Proves the lab left nothing in AWS. Run with: ./verify-teardown.sh
set -u
ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null) || { echo "No working AWS credentials." >&2; exit 1; }
echo "Checking account $ACCOUNT, region $(aws configure get region)"
pass=0; failn=0
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then echo "PASS  $d"; pass=$((pass+1)); else echo "FAIL  $d"; failn=$((failn+1)); fi; }
empty() { local r; r=$(eval "$1" 2>/dev/null); [ -z "$r" ] || [ "$r" = None ]; }
T="Name=tag:lab,Values=terraform-vpc-module"
check "no VPC tagged lab=terraform-vpc-module" empty "aws ec2 describe-vpcs --filters $T --query 'Vpcs[].VpcId' --output text"
check "no NAT Gateway tagged lab=terraform-vpc-module (they bill every hour)" empty "aws ec2 describe-nat-gateways --filter $T Name=state,Values=pending,available,deleting --query 'NatGateways[].NatGatewayId' --output text"
check "no Elastic IP tagged lab=terraform-vpc-module" empty "aws ec2 describe-addresses --filters $T --query 'Addresses[].PublicIp' --output text"
check "no internet gateway tagged lab=terraform-vpc-module" empty "aws ec2 describe-internet-gateways --filters $T --query 'InternetGateways[].InternetGatewayId' --output text"
check "no subnet tagged lab=terraform-vpc-module" empty "aws ec2 describe-subnets --filters $T --query 'Subnets[].SubnetId' --output text"
check "no state file left in terraform/" bash -c "! ls terraform/terraform.tfstate >/dev/null 2>&1"
echo
if [ "$failn" -eq 0 ]; then echo "TEARDOWN VERIFIED ($pass/$pass) in account $ACCOUNT"; else echo "NOT CLEAN: $failn leftover(s). Remove them and run this again."; fi
exit "$failn"
