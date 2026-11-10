# A free experiment: no AWS, nothing is created in the cloud. terraform_data is a local placeholder resource.
# Part 3 of the lab walks you through it.
terraform {
  required_version = ">= 1.10"
}

locals {
  zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# Version 1: count. Every resource is identified by its POSITION in the list.
resource "terraform_data" "by_count" {
  count = length(local.zones)
  input = local.zones[count.index]
}

# Version 2: for_each. Every resource is identified by its KEY.
resource "terraform_data" "by_key" {
  for_each = toset(local.zones)
  input    = each.value
}
