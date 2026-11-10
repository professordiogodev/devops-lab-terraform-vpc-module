# TODO (Part 1): the module inputs, each with a description and a type.
#
#   name        string. Validation: only lowercase letters, digits and "-", 2 to 20 characters.
#   cidr        string. Validation: a valid CIDR with a prefix length between /16 and /20.
#   az_count    number, default 2. Validation: 1 to 3.
#   enable_nat  bool, default false.
#
# Validation example:
#   validation {
#     condition     = can(cidrhost(var.cidr, 0))
#     error_message = "cidr must be a valid CIDR block."
#   }
