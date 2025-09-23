# Application Load Balancer resource
# Configures an internet-facing ALB for traffic distribution
resource "aws_lb" "alb" {
  name               = "vprofile-alb"  # Unique name for the ALB
  internal           = false           # Public-facing ALB
  load_balancer_type = "application"   # Layer 7 load balancing
  security_groups    = [var.security_group_id]  # Apply the ALB security group
  subnets            = var.public_subnet_ids    # Spread across public subnets

  enable_deletion_protection = false  # Disable for testing; enable in production

  tags = local.tags  # Apply common tags
}

# Target group for routing traffic to Tomcat instances
# Defines health checks and target port
resource "aws_lb_target_group" "tomcat_tg" {
  name     = "vprofile-tomcat-tg"  # Unique name for the target group
  port     = 8080                  # Tomcat application port
  protocol = "HTTP"                # HTTP protocol for health checks
  vpc_id   = var.vpc_id            # Associate with the VPC

  health_check {
    path                = "/"         # Health check endpoint
    protocol            = "HTTP"      # Use HTTP for checks
    matcher             = "200"       # Expect HTTP 200 response
    interval            = 30          # Check every 30 seconds
    timeout             = 5           # 5-second timeout
    healthy_threshold   = 2           # 2 consecutive successes
    unhealthy_threshold = 2           # 2 consecutive failures
  }

  tags = local.tags  # Apply common tags
}

# Listener to route HTTP traffic to the target group
# Sets up the entry point for the ALB
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn  # Reference the ALB
  port              = 80              # HTTP port
  protocol          = "HTTP"          # HTTP protocol

  default_action {
    type             = "forward"       # Forward traffic to targets
    target_group_arn = aws_lb_target_group.tomcat_tg.arn  # Target group for routing
  }
}

# Variables passed from the parent module
variable "vpc_id" {
  description = "VPC ID for ALB"  # Network scope for the ALB
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"  # Subnets for ALB distribution
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID for ALB"  # Security configuration
  type        = string
}

variable "tomcat_sg_id" {
  description = "Security group ID for Tomcat instances"  # For reference only
  type        = string
}

# Outputs to pass ALB details to other modules
output "alb_dns_name" {
  value = aws_lb.alb.dns_name  # Public DNS for CNAME setup
}

output "target_group_arn" {
  value = aws_lb_target_group.tomcat_tg.arn  # ARN for ASG attachment
}