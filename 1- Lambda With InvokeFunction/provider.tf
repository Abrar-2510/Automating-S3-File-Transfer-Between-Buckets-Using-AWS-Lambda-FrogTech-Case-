# provider.tf

provider "aws" {
  region = "us-east-1"           # Set the AWS region here
  profile = "default"            # Optional: If you use AWS CLI profiles
}
