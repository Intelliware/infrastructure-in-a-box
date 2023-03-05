terraform {
  backend "s3" {
    // Extract out this bucket key
    bucket = "{{PROJECT_PREFIX}}-terraform-state"
    key    = "ecr/terraform.tfstate"
    // Make this configurable
    region = "us-east-2"

    dynamodb_table = "{{PROJECT_PREFIX}}-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  // Make this configurable
  region = "us-east-2"
}

// This requires the AmazonEC2ContainerRegistryFullAccess / createRegistry permission
resource "aws_ecr_repository" "ecr_repository" {
  name = "{{PROJECT_PREFIX}}-repository"
}
