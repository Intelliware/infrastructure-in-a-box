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

// This requires the AmazonEC2ContainerRegistryFullAccess / createRegistry permission
resource "aws_ecr_repository" "ecr_repository" {
  name = "iiab-repository"
}
