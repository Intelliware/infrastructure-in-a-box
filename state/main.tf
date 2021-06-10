terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "iiab-terraform-state"
    key    = "state/terraform.tfstate"
    // Make this configurable
    region = "us-east-2"

    dynamodb_table = "iiab-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "iiab-terraform-state"

  lifecycle {
    prevent_destroy = true
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
  name         = "iiab-terraform-locks"

  attribute {
    // What is this for?
    name = "LockID"
    type = "S"
  }
}