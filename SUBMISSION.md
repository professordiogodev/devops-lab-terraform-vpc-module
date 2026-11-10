# Submission

Fork URL: <!-- paste the URL of your fork here -->

## Files to commit

- [ ] `terraform/` with your root module and `modules/network/`

## Questions

Answer in your own words. Where a question asks for output, paste it in a code block.

### Q1. Paste the tree of your module (`modules/network/`) and the `variable` blocks with their `validation`. What does a caller get when it passes a bad CIDR? Paste the error.

**Your answer:**

<!-- replace this line with your answer -->

### Q2. Paste the plan for adding the `qa` environment. How many resources, which addresses? Then paste the plan for removing it again. Why is `for_each` over a map safer than `count` for this?

**Your answer:**

<!-- replace this line with your answer -->

### Q3. You first wrote `count` for the subnets and then removed the first availability zone. What did the plan want to do to the other subnets, and why? How does `for_each` avoid it?

**Your answer:**

<!-- replace this line with your answer -->

### Q4. Which outputs does your module expose and which does it hide? What would the caller of the module need to know and nothing more?

**Your answer:**

<!-- replace this line with your answer -->

### Q5. The module has `enable_nat = false` by default. Why? What would it cost per month if every environment had one, and what would you change in dev to save it?

**Your answer:**

<!-- replace this line with your answer -->

### Q6. Paste the output of `./verify.sh`. It must end with **ALL CHECKS PASSED**.

**Your answer:**

<!-- replace this line with your answer -->

### Q7. **Tear down.** Paste the output of `./verify-teardown.sh`. It must end with **TEARDOWN VERIFIED**.

**Your answer:**

<!-- replace this line with your answer -->
