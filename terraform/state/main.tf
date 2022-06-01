#terraform {
#  backend "s3" {
#    // Extract out this bucket key
#    bucket = "{{PROJECT_PREFIX}}-terraform-state"
#    key    = "state/terraform.tfstate"
#    region = "{{AWS_REGION}}"
#
#    dynamodb_table = "{{PROJECT_PREFIX}}-terraform-locks"
#    encrypt        = true
#  }
#}

provider "aws" {
  region = "{{AWS_REGION}}"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "{{PROJECT_PREFIX}}-terraform-state"

  force_destroy = true

  lifecycle {
    prevent_destroy = false
  }

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  hash_key = "LockID"
  // What is this for?
  billing_mode = "PAY_PER_REQUEST"
  name         = "{{PROJECT_PREFIX}}-terraform-locks"

  attribute {
    // What is this for?
    name = "LockID"
    type = "S"
  }
}
