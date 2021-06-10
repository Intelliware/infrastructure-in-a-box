terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "iiab-terraform-state"
    key    = "network/terraform.tfstate"
    // Make this configurable
    region = "us-east-2"

    dynamodb_table = "iiab-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  // Make this configurable
  region = "us-east-2"
}

// Do we want default VPC and subnets? Sounds like no.
data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnet_ids" "default_subnet_ids" {
  vpc_id = data.aws_vpc.default_vpc.id
}