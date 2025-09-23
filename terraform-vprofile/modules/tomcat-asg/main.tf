# Launch template for Tomcat EC2 instances
# Defines the base configuration for the ASG
resource "aws_launch_template" "tomcat_lt" {
  name_prefix   = "vprofile-tomcat-lt"  # Prefix for the launch template name
  image_id      = var.ami_id            # Base AMI from data source
  instance_type = "t3.micro"            # Free-tier eligible instance type
  key_name      = var.key_name          # Existing key pair for SSH

  # User data script to set up Tomcat and build the WAR with error handling
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e  # Exit on any error to ensure reliable setup
              sudo apt update
              sudo apt upgrade -y
              sudo apt install openjdk-17-jdk -y  # Install Java runtime
              sudo apt install tomcat10 -y        # Install Tomcat server
              sudo apt install maven -y           # Install Maven for building
              sudo mkdir -p /tmp                  # Ensure temp directory exists
              sudo git clone https://github.com/Mkhwanazi-B/proton.git -b awsliftandshift /tmp/vprofile-project  # Clone repo
              cd /tmp/vprofile-project
              if ! sudo mvn package; then         # Build the WAR with error check
                echo "Maven build failed"
                exit 1
              fi
              sudo cp target/vprofile-v2.war /var/lib/tomcat10/webapps/ROOT.war  # Deploy as root app
              sudo systemctl start tomcat10       # Start Tomcat service
              sudo systemctl enable tomcat10      # Enable on boot
              EOF
  )

  network_interfaces {
    associate_public_ip_address = true  # Assign public IP for accessibility
    security_groups             = [var.security_group_id]  # Apply Tomcat SG
  }

  tag_specifications {
    resource_type = "instance"  # Apply tags to instances
    tags          = var.tags  # Common tags
  }
}

# Temporary instance to create a custom AMI
# Used to bake the user data configuration into an AMI
resource "aws_instance" "tomcat_temp" {
  ami           = aws_launch_template.tomcat_lt.id  # Use the launch template
  instance_type = "t3.micro"                        # Free-tier eligible
  key_name      = var.key_name                      # Existing key pair
  user_data     = aws_launch_template.tomcat_lt.user_data  # Apply user data
  subnet_id     = element(var.subnet_ids, 0)        # Use first public subnet
  associate_public_ip_address = true                # Public IP for access
  security_groups = [var.security_group_id]         # Apply Tomcat SG

  tags = merge(var.tags, { Name = "vprofile-tomcat-temp" })  # Temp instance tag

  # Create AMI and terminate instance post-setup
  provisioner "local-exec" {
    command = "aws ec2 create-image --instance-id ${self.id} --name vprofile-tomcat-ami --description 'Custom AMI for Tomcat' --region eu-north-1 --output text > ami_id.txt && aws ec2 terminate-instances --instance-ids ${self.id} --region eu-north-1"
  }
}

# Data source to retrieve the created custom AMI
data "aws_ami" "custom_tomcat" {
  most_recent = true  # Use the latest created AMI
  filter {
    name   = "name"    # Filter by AMI name
    values = ["vprofile-tomcat-ami"]
  }
  depends_on = [aws_instance.tomcat_temp]  # Wait for temp instance to create AMI
}

# Auto Scaling Group for Tomcat instances
# Manages scaling based on ELB health checks
resource "aws_autoscaling_group" "tomcat_asg" {
  name                = "vprofile-tomcat-asg"  # Unique ASG name
  vpc_zone_identifier = var.subnet_ids         # Spread across public subnets
  target_group_arns   = [var.target_group_arn] # Link to ALB target group
  health_check_type   = "ELB"                  # Use ELB for health checks
  min_size            = 2                      # Minimum instances
  max_size            = 4                      # Maximum instances
  desired_capacity    = 2                      # Desired initial count

  launch_template {
    id      = data.aws_ami.custom_tomcat.id  # Use custom AMI
    version = "$Latest"                     # Always use the latest version
  }

  tag {
    key                 = "Name"              # Tag key for instances
    value               = "vprofile-tomcat"   # Tag value
    propagate_at_launch = true                # Apply tag on launch
  }
}

# Variables passed from the parent module
variable "ami_id" {
  description = "AMI ID for launch template"  # Base AMI for initial setup
  type        = string
}

variable "key_name" {
  description = "Key pair name"  # SSH key for instance access
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for Tomcat instances"  # Network security
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"  # Subnets for instance placement
  type        = list(string)
}

variable "target_group_arn" {
  description = "Target group ARN for ASG"  # Link to ALB
  type        = string
}

