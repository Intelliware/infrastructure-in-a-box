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
  allocated_storage    = 20 // gb
  engine               = "postgres"
  engine_version       = "13.4"
  instance_class       = "db.t3.micro"
  db_name              = "{{PROJECT_PREFIX}}db"
  identifier           = "{{PROJECT_PREFIX}}db"
  username             = "foo"
  password             = "exposingDefaultsIsBad"
  parameter_group_name = "default.postgres13"
  skip_final_snapshot  = true
  apply_immediately = true
}
