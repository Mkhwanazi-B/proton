# Define input variables for the Terraform configuration
# These allow customization without hardcoding values
variable "my_ip" {
  description = "Your laptop's public IP for SSH access" # Restrict SSH to your IP
  type        = string
  default     = "102.33.220.53/32" # Default IP with CIDR notation
}

# variables.tf  (root or modules/security-groups/variables.tf)
variable "env_name" {
  description = "Environment name used in tags"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "vprofile"
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}