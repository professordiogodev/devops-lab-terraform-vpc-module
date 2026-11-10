#!/usr/bin/env python3
import glob, ipaddress, json, os, re, subprocess, sys
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
os.chdir(ROOT)
passed = failed = 0


def check(desc, ok, hint=""):
    global passed, failed
    if ok:
        passed += 1; print("PASS  " + desc)
    else:
        failed += 1; print("FAIL  " + desc + (("   -> " + hint) if hint else ""))


def aws(*a):
    try:
        return json.loads(subprocess.check_output(("aws",) + a + ("--output", "json"), stderr=subprocess.DEVNULL, timeout=60) or "null")
    except Exception:
        return None


def sh(c):
    r = subprocess.run(c, shell=True, capture_output=True, text=True)
    return r.returncode, r.stdout


def rd(p):
    try:
        return open(p).read()
    except OSError:
        return ""


print("== The module ==")
mdir = "terraform/modules/network"
mt = rd(mdir + "/main.tf"); mv = rd(mdir + "/variables.tf"); mo = rd(mdir + "/outputs.tf")
check("terraform/modules/network has main.tf, variables.tf and outputs.tf", all(len(x.strip()) > 200 for x in (mt, mv)) and "output" in mo and "TODO" not in mo)
for var in ("name", "cidr", "az_count", "enable_nat"):
    check("variable %s has a type and a description" % var, re.search(r'variable\s+"%s"\s*\{[^}]*?description[^}]*?\}' % var, mv, re.S) is not None and re.search(r'variable\s+"%s"\s*\{.*?type\s*=' % var, mv, re.S) is not None)
check("validation blocks on name, cidr and az_count (at least 3)", mv.count("validation {") >= 3, "found %d" % mv.count("validation {"))
check("enable_nat defaults to false", re.search(r'variable\s+"enable_nat".*?default\s*=\s*false', mv, re.S) is not None)
check("subnets use for_each (not count) and cidrsubnet()", "for_each" in mt and "cidrsubnet" in mt and not re.search(r'resource\s+"aws_subnet"[^{]*\{[^}]*\bcount\b', mt, re.S))
check("the NAT gateway is conditional (count = var.enable_nat ...)", re.search(r'aws_nat_gateway".*?count\s*=\s*var\.enable_nat', mt, re.S) is not None)
check("outputs: vpc_id, public_subnet_ids and private_subnet_ids", all(('output "%s"' % o) in mo for o in ("vpc_id", "public_subnet_ids", "private_subnet_ids")))

print("== The root configuration ==")
root = rd("terraform/main.tf")
check("the module is called once, with for_each over var.environments", len(re.findall(r'module\s+"[^"]+"\s*\{', root)) == 1 and re.search(r"for_each\s*=\s*var\.environments", root) is not None)
check("terraform fmt -check is clean", sh("terraform -chdir=terraform fmt -check -recursive")[0] == 0, "terraform -chdir=terraform fmt -recursive")
check("terraform validate passes", sh("terraform -chdir=terraform init -input=false -backend=false >/dev/null 2>&1; terraform -chdir=terraform validate")[0] == 0)
bad = sh("terraform -chdir=terraform plan -input=false -no-color -var 'environments={\"x\"=\"10.0.0.0/8\"}' 2>&1")
check("a CIDR outside /16-/20 is rejected by your validation (try /8)", "validation" in bad[1].lower() or "must" in bad[1].lower() or bad[0] != 0)
tracked = sh("git ls-files")[1].split("\n")
check("no state file, .terraform/ or tfvars committed", not [f for f in tracked if re.search(r"\.tfstate|(^|/)\.terraform/|\.tfvars$", f)])
check("no AWS keys in the repository", sh("git grep -lE 'AKIA[0-9A-Z]{16}' -- . ':!.lab' ':!verify.sh'")[1].strip() == "")

print("== The networks in AWS ==")
F = "Name=tag:lab,Values=terraform-vpc-module"
vpcs = (aws("ec2", "describe-vpcs", "--filters", F) or {}).get("Vpcs", [])
by = {next((t["Value"] for t in v.get("Tags", []) if t["Key"] == "Environment"), "?"): v for v in vpcs}
check("exactly two VPCs, for dev and staging (qa was added and removed again)", sorted(by) == ["dev", "staging"], "found %s" % sorted(by))
check("dev is 10.10.0.0/16 and staging is 10.20.0.0/16", by.get("dev", {}).get("CidrBlock") == "10.10.0.0/16" and by.get("staging", {}).get("CidrBlock") == "10.20.0.0/16")
for env, v in sorted(by.items()):
    VF = "Name=vpc-id,Values=" + v["VpcId"]
    subs = (aws("ec2", "describe-subnets", "--filters", VF) or {}).get("Subnets", [])
    rts = (aws("ec2", "describe-route-tables", "--filters", VF) or {}).get("RouteTables", [])
    vnet = ipaddress.ip_network(v["CidrBlock"])
    pub = [s for s in subs if s.get("MapPublicIpOnLaunch")]
    check("%s: 2 public and 2 private subnets in 2 availability zones, all /24 inside the VPC" % env,
          len(subs) == 4 and len(pub) == 2 and len({s["AvailabilityZone"] for s in subs}) == 2 and all(ipaddress.ip_network(s["CidrBlock"]).subnet_of(vnet) and s["CidrBlock"].endswith("/24") for s in subs))
    def to_igw(sid):
        rt = next((r for r in rts if any(a.get("SubnetId") == sid for a in r["Associations"])), None)
        return bool(rt) and any(x.get("DestinationCidrBlock") == "0.0.0.0/0" and x.get("GatewayId", "").startswith("igw-") for x in rt["Routes"])
    check("%s: the public subnets route to the internet gateway, the private ones do not" % env,
          all(to_igw(s["SubnetId"]) for s in pub) and not any(to_igw(s["SubnetId"]) for s in subs if s not in pub))
nats = (aws("ec2", "describe-nat-gateways", "--filter", F, "Name=state,Values=available,pending") or {}).get("NatGateways", [])
check("no NAT Gateway exists (enable_nat is off)", not nats)

print("== Terraform state ==")
rc, out = sh("terraform -chdir=terraform state list")
check("the state tracks both environments, and only those", rc == 0 and 'module.network["dev"]' in out and 'module.network["staging"]' in out and 'module.network["qa"]' not in out)
rc, out = sh("terraform -chdir=terraform plan -detailed-exitcode -input=false -no-color")
check("terraform plan finds nothing to change", rc == 0, "plan exit code %d" % rc)

print()
print(("ALL CHECKS PASSED (%d/%d)" % (passed, passed)) if failed == 0 else ("%d check(s) failed, %d passed" % (failed, passed)))
sys.exit(1 if failed else 0)
