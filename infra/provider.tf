# This file configures the AWS provider.
# We're setting the required version and the default region.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
# The region is passed in from our variables file.
provider "aws" {
  region = var.aws_region
}