terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "{{PROJECT_PREFIX}}-terraform-state"
    key    = "db/terraform.tfstate"
    region = "{{AWS_REGION}}"

    dynamodb_table = "{{PROJECT_PREFIX}}-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "{{AWS_REGION}}"
}

resource "aws_db_instance" "test-db" {
  allocated_storage    = 10 // gb
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  db_name              = "mydb"
  username             = "foo"
  password             = "exposingDefaultsIsBad"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  apply_immediately = true
}
