terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "{{PROJECT_PREFIX}}-terraform-state"
    key    = "network/terraform.tfstate"
    region = "{{AWS_REGION}}"

    dynamodb_table = "{{PROJECT_PREFIX}}-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "{{AWS_REGION}}"
}

resource "aws_vpc" "main_vpc" {
  tags = {
    Name = "{{PROJECT_PREFIX}}-VPC"
  }

  enable_dns_hostnames = true
  cidr_block = "10.1.0.0/16"
}

data "aws_availability_zones" "regional_availability_zones" {}

locals {
  az_index_to_letter_map = {
    "0" = "a"
    "1" = "b"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_subnets)
  vpc_id     = aws_vpc.main_vpc.id
  availability_zone = data.aws_availability_zones.regional_availability_zones.names[count.index]
  cidr_block = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "{{PROJECT_PREFIX}}-PublicSubnet-AZ${local.az_index_to_letter_map[count.index]}"
  }
}

resource "aws_subnet" "private" {
  count = length(var.private_subnets)
  vpc_id     = aws_vpc.main_vpc.id
  availability_zone = data.aws_availability_zones.regional_availability_zones.names[count.index]
  cidr_block = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  tags = {
    Name = "{{PROJECT_PREFIX}}-PrivateSubnet-AZ${local.az_index_to_letter_map[count.index]}"
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "{{PROJECT_PREFIX}}-InternetGateway"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name = "Public"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Private"
  }
}

resource "aws_route_table_association" "public_subnets" {
  count = length(var.public_subnets)
  route_table_id = aws_route_table.public.id
  subnet_id = aws_subnet.public[count.index].id
}

resource "aws_route_table_association" "private_subnets" {
  count = length(var.private_subnets)
  route_table_id = aws_route_table.private.id
  subnet_id = aws_subnet.private[count.index].id
}

resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main_vpc.id

  subnet_ids = aws_subnet.public[*].id

  tags = {
    Name = "{{PROJECT_PREFIX}}-Public-NACL"
  }
}

resource "aws_network_acl_rule" "public_response_egress" {
  network_acl_id = aws_network_acl.public_nacl.id
  egress = true
  from_port = 32768
  to_port = 65535
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 100
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_http_egress" {
  network_acl_id = aws_network_acl.public_nacl.id
  egress = true
  from_port = 80
  to_port = 80
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 101
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_https_egress" {
  network_acl_id = aws_network_acl.public_nacl.id
  egress = true
  from_port = 443
  to_port = 443
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 102
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_http_ingress" {
  network_acl_id = aws_network_acl.public_nacl.id
  egress = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 100
  from_port = 80
  to_port = 80
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_https_ingress" {
  network_acl_id = aws_network_acl.public_nacl.id
  egress = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 101
  from_port = 443
  to_port = 443
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_ssh_ingress" {
  network_acl_id = aws_network_acl.public_nacl.id
  egress = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 102
  from_port = 22
  to_port = 22
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_response_ingress" {
  network_acl_id = aws_network_acl.public_nacl.id
  egress = false
  protocol       = "tcp"
  rule_action    = "allow"
  rule_number    = 103
  from_port = 32768
  to_port = 65535
  cidr_block = "0.0.0.0/0"
}

resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main_vpc.id

  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "{{PROJECT_PREFIX}}-Private-NACL"
  }
}

resource "aws_network_acl_rule" "private_egress" {
  network_acl_id = aws_network_acl.private_nacl.id
  egress = true
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
  cidr_block = aws_vpc.main_vpc.cidr_block
}

resource "aws_network_acl_rule" "private_ingress" {
  network_acl_id = aws_network_acl.private_nacl.id
  egress = false
  protocol       = "-1"
  rule_action    = "allow"
  rule_number    = 100
  cidr_block = aws_vpc.main_vpc.cidr_block
}

resource "aws_security_group" "public_security_group" {
  name = "{{PROJECT_PREFIX}}-public"
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_security_group_rule" "public_http_ingress" {
  cidr_blocks = ["0.0.0.0/0"]
  from_port         = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.public_security_group.id
  to_port           = 80
  type              = "ingress"
}

resource "aws_security_group_rule" "public_https_ingress" {
  cidr_blocks = ["0.0.0.0/0"]
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.public_security_group.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_security_group_rule" "public_ssh_ingress" {
  cidr_blocks = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.public_security_group.id
  to_port           = 22
  type              = "ingress"
}

resource "aws_security_group_rule" "public_egress" {
  cidr_blocks = ["0.0.0.0/0"]
  from_port = 0
  protocol          = "-1"
  security_group_id = aws_security_group.public_security_group.id
  to_port = 0
  type              = "egress"
}
