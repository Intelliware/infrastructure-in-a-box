output "vpc_id" {
  description = "The ID of the VPC to place resources under"
  value = data.aws_vpc.default_vpc.id
}

output "aws_subnet_ids" {
  description = "The IDs of subnets to place resources under"
  value = data.aws_subnet_ids.default_subnet_ids.ids
}