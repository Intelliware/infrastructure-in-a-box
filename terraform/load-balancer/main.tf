terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "pinkkeyboard-terraform-state"
    key    = "load-balancer/terraform.tfstate"
    region = "us-east-2"

    dynamodb_table = "pinkkeyboard-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "pinkkeyboard-terraform-state"
    key = "network/terraform.tfstate"
    region = "us-east-2"
  }
}

data "terraform_remote_state" "eks" {
  backend = "s3"
  config = {
    bucket = "pinkkeyboard-terraform-state"
    key = "eks/terraform.tfstate"
    region = "us-east-2"
  }
}

resource "aws_alb" "load_balancer" {

}

resource "aws_alb_target_group" "target_group" {
  name = "pinkkeyboard-target-group"
  port = 32000
  protocol = "HTTP"
  target_type = "instance"
  vpc_id = data.terraform_remote_state.network.vpc_id
}

resource "aws_alb_target_group_attachment" "target_group_attachment" {
  target_group_arn = ""
  target_id        = ""
}