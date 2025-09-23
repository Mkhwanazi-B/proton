# Configure Terraform to use an existing S3 bucket for remote state storage
# This ensures state is centralized and versioned, avoiding local file conflicts
terraform {
  backend "s3" {
    bucket = "terraform-state-file-999999" # Existing S3 bucket for state
    key    = "terraform/terraform.tfstate" # Path within the bucket
    region = "eu-north-1"                  # Match AWS provider region
  }
}