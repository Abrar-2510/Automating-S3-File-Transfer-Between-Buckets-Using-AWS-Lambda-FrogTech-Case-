
# Create the source S3 bucket
resource "aws_s3_bucket" "external" {
  bucket = "frogtech-us-external"

  tags = {
    Environment = var.Environment
    Owner       = var.Owner
  }
}

# Create the destination S3 bucket
resource "aws_s3_bucket" "internal" {
  bucket = "frogtech-us-internal"

  tags = {
    Environment = var.Environment
    Owner       = var.Owner
  }
}
