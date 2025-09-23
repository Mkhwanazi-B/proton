# Security group for the Application Load Balancer
# Matches manual setup allowing HTTP and HTTPS from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "vprofile-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id  # Reference the VPC from the parent module

  ingress {
    from_port   = 80    # HTTP port
    to_port     = 80    # HTTP port
    protocol    = "tcp" # TCP protocol
    cidr_blocks = ["0.0.0.0/0"]  # Allow all inbound HTTP traffic
  }

  ingress {
    from_port   = 443   # HTTPS port
    to_port     = 443   # HTTPS port
    protocol    = "tcp" # TCP protocol
    cidr_blocks = ["0.0.0.0/0"]  # Allow all inbound HTTPS traffic
  }

  egress {
    from_port   = 0     # Allow all outbound ports
    to_port     = 0     # Allow all outbound ports
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = var.tags  # Apply common tags
}

# Security group for Tomcat EC2 instances
# Replicates manual rules for Tomcat port and SSH access
resource "aws_security_group" "tomcat_sg" {
  name        = "vprofile-tomcat-sg"
  description = "Security group for Tomcat EC2 instances"
  vpc_id      = var.vpc_id  # Reference the VPC from the parent module

  ingress {
    from_port       = 8080  # Tomcat application port
    to_port         = 8080  # Tomcat application port
    protocol        = "tcp" # TCP protocol
    security_groups = [aws_security_group.alb_sg.id]  # Allow traffic from ALB
  }

  ingress {
    from_port   = 22    # SSH port
    to_port     = 22    # SSH port
    protocol    = "tcp" # TCP protocol
    cidr_blocks = [var.my_ip]  # Restrict SSH to the user's IP
  }

  egress {
    from_port   = 0     # Allow all outbound ports
    to_port     = 0     # Allow all outbound ports
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = var.tags  # Apply common tags
}

# Security group for supporting services (MySQL, Memcached, RabbitMQ)
# Matches manual rules for specific ports and Tomcat access
resource "aws_security_group" "support_sg" {
  name        = "vprofile-support-sg"
  description = "Security group for MySQL, Memcached, RabbitMQ"
  vpc_id      = var.vpc_id  # Reference the VPC from the parent module

  ingress {
    from_port       = 3306  # MySQL port
    to_port         = 3306  # MySQL port
    protocol        = "tcp" # TCP protocol
    security_groups = [aws_security_group.tomcat_sg.id]  # Allow traffic from Tomcat
  }

  ingress {
    from_port       = 11211 # Memcached port
    to_port         = 11211 # Memcached port
    protocol        = "tcp" # TCP protocol
    security_groups = [aws_security_group.tomcat_sg.id]  # Allow traffic from Tomcat
  }

  ingress {
    from_port       = 5672  # RabbitMQ port
    to_port         = 5672  # RabbitMQ port
    protocol        = "tcp" # TCP protocol
    security_groups = [aws_security_group.tomcat_sg.id]  # Allow traffic from Tomcat
  }

  ingress {
    from_port   = 22    # SSH port
    to_port     = 22    # SSH port
    protocol    = "tcp" # TCP protocol
    cidr_blocks = [var.my_ip]  # Restrict SSH to the user's IP
  }

  egress {
    from_port   = 0     # Allow all outbound ports
    to_port     = 0     # Allow all outbound ports
    protocol    = "-1"  # All protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic
  }

  tags = var.tags  # Apply common tags
}

# Variables passed from the parent module
variable "vpc_id" {
  description = "VPC ID for security groups"  # Identifies the network scope
  type        = string
}

variable "my_ip" {
  description = "IP address for SSH access"  # User's IP for secure access
  type        = string
}

# Outputs to pass security group IDs to other modules
output "alb_sg_id" {
  value = aws_security_group.alb_sg.id  # ID for ALB security group
}

output "tomcat_sg_id" {
  value = aws_security_group.tomcat_sg.id  # ID for Tomcat security group
}

output "support_sg_id" {
  value = aws_security_group.support_sg.id  # ID for support services security group
}

