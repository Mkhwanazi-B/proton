# ---------------------------------------------------------------------------
# DATA SOURCES
# ---------------------------------------------------------------------------
# Use the AWS-default VPC instead of creating a new one (keeps demo simple)
data "aws_vpc" "default" {
  default = true
}

# Discover all public subnets in the default VPC that auto-assign public IPs
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Always pull the latest Ubuntu 22.04 LTS AMI (Canonical owner account)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Look up the private hosted zone we will use for internal DNS records
data "aws_route53_zone" "vprofile_zone" {
  name         = "vprofile.ini." # trailing dot required
  private_zone = true
}

# ---------------------------------------------------------------------------
# LOCAL VALUES – SINGLE SOURCE OF TAGS
# ---------------------------------------------------------------------------
locals {
  common_tags = {
    Name        = "vprofile"   # human-readable resource name
    Environment = "dev"        # dev / staging / prod
    ManagedBy   = "Terraform"
    Project     = "proton"
  }
}

# ---------------------------------------------------------------------------
# MODULE CALLS – TAGS EXPLICITLY PASSED IN TO KEEP MODULES GENERIC
# ---------------------------------------------------------------------------

# Security groups for ALB, Tomcat, DB, Memcached, RabbitMQ, SSH
module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = data.aws_vpc.default.id
  my_ip  = var.my_ip                # SSH CIDR from variables.tf
  tags   = local.common_tags        # uniform tagging
}

# Application Load Balancer in public subnets
module "alb" {
  source            = "./modules/alb"
  vpc_id            = data.aws_vpc.default.id
  public_subnet_ids = data.aws_subnets.public.ids
  security_group_id = module.security_groups.alb_sg_id
  tomcat_sg_id      = module.security_groups.tomcat_sg_id
  tags              = local.common_tags
}

# Auto-Scaling Group of Tomcat instances (private subnets, attached to ALB)
module "tomcat_asg" {
  source            = "./modules/tomcat-asg"
  ami_id            = data.aws_ami.ubuntu.id
  key_name          = "vprofile-prod"   # existing key pair
  security_group_id = module.security_groups.tomcat_sg_id
  subnet_ids        = data.aws_subnets.public.ids
  target_group_arn  = module.alb.target_group_arn
  tags              = local.common_tags
}

# Individual EC2 instances: MySQL, Memcached, RabbitMQ + Route 53 records
module "supporting_instances" {
  source            = "./modules/supporting-instances"
  ami_id            = data.aws_ami.ubuntu.id
  key_name          = "vprofile-prod"
  security_group_id = module.security_groups.support_sg_id
  subnet_ids        = data.aws_subnets.public.ids
  route53_zone_id   = data.aws_route53_zone.vprofile_zone.zone_id
  tags              = local.common_tags
}