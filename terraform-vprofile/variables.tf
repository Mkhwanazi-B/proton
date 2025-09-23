# Define input variables for the Terraform configuration
# These allow customization without hardcoding values
variable "my_ip" {
  description = "Your laptop's public IP for SSH access" # Restrict SSH to your IP
  type        = string
  default     = "102.33.220.53/32" # Default IP with CIDR notation
}