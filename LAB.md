# LAB | Terraform: One Network Module, Three Environments

## The situation

Clippy has a dev network and a staging network. They were built by copying the same Terraform folder, and the copies have drifted: one has a typo in a route, the other forgot a subnet. Now the new QA team wants a third network *this afternoon*, and nobody wants a third copy.

You will turn the network into a **module**: a function with inputs, validation and outputs. You will call it once per environment with `for_each` over a map, so that adding the QA environment is **one line** and removing it is the same line deleted. You will also see, with your own eyes, why `count` is dangerous for things that have identities.

> **Your mission**
> - Write the module `modules/network`: a VPC, public and private subnets across availability zones, routes, and an **optional** NAT Gateway (off by default)
> - Give the module a contract: typed variables with descriptions and **validation** that rejects bad input with a clear message
> - Call it from the root with `for_each` over the environments
> - Add the `qa` environment, read the plan, remove it again
> - Run a free experiment that shows what `count` does to your resources when the list changes
> - Tear it down and prove it

**Time:** 90-105 min | **Cost:** free (the NAT Gateway is off: it would cost money every hour) | **You need:** an AWS administrator user, the AWS CLI v2, Terraform 1.10 or newer, git and a terminal. Everything uses `us-east-1`.

---

## Part 0 - Look around

1. **Fork** this repository and clone it. In `terraform/` you have a root configuration with a map of environments (`dev` and `staging`) and an empty `modules/network/` folder with a `TODO` list in each file.
2. Read the TODO list of the module before you write anything. A module is a small API: decide what goes **in** (variables), what comes **out** (outputs) and what stays **inside** (everything else).

---

## Part 1 - The module

Write the three files in `terraform/modules/network/`:

**`variables.tf`**: four inputs, each with `type` and `description`:

| Variable | Rules |
|----------|-------|
| `name` | validation: 2 to 20 characters, lowercase letters, digits and `-` |
| `cidr` | validation: a valid CIDR with a prefix between `/16` and `/20` |
| `az_count` | default `2`, validation: 1 to 3 |
| `enable_nat` | `bool`, default `false` |

**`main.tf`**: the resources listed in the TODO. Two rules:

- Subnets use **`for_each` over the zone names** (`toset(local.azs)`), not `count`. Each subnet gets a `/24` from `cidrsubnet()`.
- The NAT Gateway, its Elastic IP and the private route table exist **only** when `enable_nat` is true (`count = var.enable_nat ? 1 : 0`). A NAT Gateway costs money every hour.

**`outputs.tf`**: `vpc_id`, `public_subnet_ids` and `private_subnet_ids` (lists). Do not output more than a caller needs.

Try the validation before you ever apply: call the module with `cidr = "10.0.0.0/8"` and read the error.

> **Think** Validation runs at *plan* time, before anything is created. Why is that worth more than an error from AWS after ten resources already exist?

---

## Part 2 - Call it for every environment

In the root `main.tf` do the `TODO`: one `module "network"` block with `for_each = var.environments`, passing `name = each.key` and `cidr = each.value`. Add an output `vpc_ids` that maps each environment name to its VPC id.

```bash
cd terraform
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Count the resources in the plan: how many per environment? Apply it. Look at the resource addresses with `terraform state list`.

Now the point of the whole lab. Add a third environment to the map in the root, **one line**:

```hcl
qa = "10.30.0.0/16"
```

Run `terraform plan`. How many resources does it add, and does it touch `dev` or `staging`? Apply it. Then delete the line and plan again: it must destroy **only** `qa`. Apply that too.

> **Think** The plan for adding `qa` touched nothing else. What property of `for_each` over a map makes that true? What would the addresses look like if the environments were in a list used with `count`?

---

## Part 3 - Why not count? (a free experiment)

In `experiments/count-vs-for-each/` there is a tiny configuration with **no AWS**. It creates the same three zone names twice: once with `count`, once with `for_each`. Nothing leaves your laptop.

```bash
cd experiments/count-vs-for-each
terraform init
terraform apply
```

Now edit `main.tf` and remove the **first** zone from the list (`us-east-1a`), then:

```bash
terraform plan
```

Compare the two halves of the plan. Which resources does the `count` version want to change or destroy? Which does the `for_each` version destroy?

Put the zone back, destroy the experiment (`terraform destroy`) and go back to the main folder.

> **Think** `count` identifies resources by *position* (`[0]`, `[1]`, `[2]`). Imagine those were three subnets with servers in them. What would the `count` plan do to your servers when you removed one zone from the start of the list?

---

## Part 4 - The NAT switch (optional but worth a minute)

Pass `enable_nat = true` for `dev` only (for example `enable_nat = each.key == "dev"` in the module call) and look at the plan: how many extra resources? Apply it **only if you will destroy it in the next ten minutes**. Switch it back to `false` and apply again; confirm the NAT Gateway is gone in the console.

> **Think** A NAT Gateway costs roughly 32 dollars per month, per gateway, even with no traffic. If every environment in a company had its own, what would you change for dev and what would you keep for production?

---

## Part 5 - Prove it

```bash
./verify.sh
```

It checks the module (typed variables, validation, `for_each`, the conditional NAT, the outputs), the root, and the **real networks** in AWS: exactly `dev` and `staging` (so `qa` must be gone again), their subnets, routes and no NAT Gateway. It ends by running `terraform plan` and requiring "no changes". Fix what is red and run it again until it ends with **ALL CHECKS PASSED**.

> **Stuck?** `Invalid for_each argument`: the keys must be known at plan time (strings from a variable are, ids of resources not yet created are not). `Module not installed`: run `terraform init` again after adding a module block. `A managed resource has not been declared`: check the name in the output (`module.network[each.key]`, or use a `for` expression over `module.network`).

---

## Level up (optional)

- Add a `terraform test` file (`.tftest.hcl`) that passes a bad CIDR and `expect_failures` on your validation.
- Add a `tags` input (a map) that is merged into every resource, and a `lifecycle { precondition }` that stops `enable_nat` with `az_count = 1`.
- Publish the module in its own Git repository and call it with `source = "git::https://github.com/<you>/<repo>.git//modules/network?ref=v1.0.0"`. Why pin a version?
- Add `outputs` that expose the NAT gateway id only when it exists, using `one()` or `try()`.

<!-- teardown:start (generated by labs.py, do not edit) -->
## Tear down (mandatory)

Resources left behind cost money, keep doors open and pollute the next lab. Removing what you created is part of the job, so it is part of the submission: **you must prove it is gone**.

Do this **last**, after you have pasted your `verify` output into `SUBMISSION.md` (once you tear down, the lab can no longer be verified).

1. Run `./teardown.sh` (it runs `terraform destroy`).

Then run the proof:

```bash
./verify-teardown.sh
```

It prints a list of checks and must end with **TEARDOWN VERIFIED**. If it reports leftovers, remove them and run it again. Paste the full output in your submission.
<!-- teardown:end -->

<!-- submission:start (generated by labs.py, do not edit) -->
## Submission

Answer the questions in `SUBMISSION.md` in **your fork** (paste output in code blocks where asked), push, then submit the **URL of your fork**.

**Files to commit**

- `terraform/` with your root module and `modules/network/`

**Questions to answer**

1. Paste the tree of your module (`modules/network/`) and the `variable` blocks with their `validation`. What does a caller get when it passes a bad CIDR? Paste the error.
2. Paste the plan for adding the `qa` environment. How many resources, which addresses? Then paste the plan for removing it again. Why is `for_each` over a map safer than `count` for this?
3. You first wrote `count` for the subnets and then removed the first availability zone. What did the plan want to do to the other subnets, and why? How does `for_each` avoid it?
4. Which outputs does your module expose and which does it hide? What would the caller of the module need to know and nothing more?
5. The module has `enable_nat = false` by default. Why? What would it cost per month if every environment had one, and what would you change in dev to save it?
6. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.
7. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.
<!-- submission:end -->
