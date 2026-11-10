# TODO (Part 1): the network module.
#
#   - data "aws_availability_zones": the first var.az_count zones
#   - aws_vpc (var.cidr, DNS hostnames on), tag Name = var.name
#   - aws_internet_gateway
#   - public subnets: one per zone, for_each over the zone names (NOT count), /24s from cidrsubnet()
#   - private subnets: one per zone, for_each, other /24s
#   - one public route table (0.0.0.0/0 -> internet gateway) with associations
#   - ONLY when var.enable_nat is true: an Elastic IP, a NAT Gateway in the first public subnet, a private
#     route table (0.0.0.0/0 -> NAT) and its associations. Use count = var.enable_nat ? 1 : 0.
#     (A NAT Gateway costs money every hour: the default is off.)
#   - tag everything Name = "${var.name}-..." and Environment = var.name
