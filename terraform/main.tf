terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      lab = "terraform-vpc-module"
    }
  }
}

# One network per environment. Adding an environment must be ONE line here.
variable "environments" {
  description = "Environment name to VPC CIDR"
  type        = map(string)
  default = {
    dev     = "10.10.0.0/16"
    staging = "10.20.0.0/16"
  }
}

# TODO (Part 2): call the module once per environment with for_each over var.environments.
#   source = "./modules/network", name = each.key, cidr = each.value
#   Leave enable_nat at its default.
