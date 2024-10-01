# Create variables for environment and owner
variable "Environment" {
  description = "The environment for the S3 bucket"
  type        = string
}

variable "Owner" {
  description = "The owner of the S3 bucket"
  type        = string
}
