# Data sources for existing AWS resources to avoid recreation
# Fetch the default VPC for simplicity in this test environment
data "aws_vpc" "default" {
  default = true # Use the default VPC provided by AWS
}

# Fetch public subnets within the default VPC
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id" # Filter by VPC ID
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "map-public-ip-on-launch" # Ensure subnets auto-assign public IPs
    values = ["true"]
  }
}

# Fetch the latest Ubuntu 22.04 LTS AMI for EC2 instances
data "aws_ami" "ubuntu" {
  most_recent = true             # Always use the latest version
  owners      = ["099720109477"] # Canonical's AWS account ID
  filter {
    name   = "name" # Filter by AMI name pattern
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Fetch the existing Route 53 private hosted zone
data "aws_route53_zone" "vprofile_zone" {
  name         = "vprofile.ini." # Exact zone name with trailing dot
  private_zone = true            # Confirm it's a private zone
}

# Local values to avoid repetition in resource definitions
locals {
  tags = {
    Name        = "vprofile" # Resource naming convention
    Environment = "prod"     # Environment identifier
  }
}

# Modules to organize infrastructure components
module "security_groups" {
  source = "./modules/security-groups" # Local module path
  vpc_id = data.aws_vpc.default.id     # Pass VPC ID to module
  my_ip  = var.my_ip                   # Pass SSH access IP
}

module "alb" {
  source            = "./modules/alb"                     # Local module path
  vpc_id            = data.aws_vpc.default.id             # Pass VPC ID
  public_subnet_ids = data.aws_subnets.public.ids         # Pass public subnet IDs
  security_group_id = module.security_groups.alb_sg_id    # Pass ALB SG ID
  tomcat_sg_id      = module.security_groups.tomcat_sg_id # Pass Tomcat SG ID
}

module "tomcat_asg" {
  source            = "./modules/tomcat-asg"              # Local module path
  ami_id            = data.aws_ami.ubuntu.id              # Pass base AMI ID
  key_name          = "vprofile-prod"                     # Use existing key pair
  security_group_id = module.security_groups.tomcat_sg_id # Pass Tomcat SG ID
  subnet_ids        = data.aws_subnets.public.ids         # Pass public subnet IDs
  target_group_arn  = module.alb.target_group_arn         # Pass target group ARN
}

module "supporting_instances" {
  source            = "./modules/supporting-instances"            # Local module path
  ami_id            = data.aws_ami.ubuntu.id                      # Pass base AMI ID
  key_name          = "vprofile-prod"                             # Use existing key pair
  security_group_id = module.security_groups.support_sg_id        # Pass support SG ID
  subnet_ids        = data.aws_subnets.public.ids                 # Pass public subnet IDs
  route53_zone_id   = data.aws_route53_zone.vprofile_zone.zone_id # Pass zone ID
}