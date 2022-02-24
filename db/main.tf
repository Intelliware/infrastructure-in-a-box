terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "iiab-terraform-state"
    key    = "ecr/terraform.tfstate"
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

resource "aws_db_instance" "test-db" {
  allocated_storage    = 10 // gb
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "exposingDefaultsIsBad"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}
