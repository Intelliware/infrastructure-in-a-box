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
