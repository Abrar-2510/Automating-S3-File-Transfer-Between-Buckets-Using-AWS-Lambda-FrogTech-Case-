# provider.tf

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0" # Ensure you are using a compatible version
    }
  }

  required_version = ">= 1.0"
}

provider "aws" {
  region = "us-east-1"           # Set the AWS region here
  profile = "default"            # Optional: If you use AWS CLI profiles
}
