# MySQL Instance resource
# Deploys a MySQL server with user data for initial setup
resource "aws_instance" "mysql" {
  ami           = var.ami_id            # Use Ubuntu AMI
  instance_type = "t3.micro"            # Free-tier eligible
  key_name      = var.key_name          # Existing key pair
  subnet_id     = element(var.subnet_ids, 0)  # First public subnet
  associate_public_ip_address = true    # Public IP for testing
  security_groups = [var.security_group_id]  # Apply support SG

  # User data to install and configure MySQL
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e  # Exit on error
              sudo apt update
              sudo apt install mariadb-server -y
              sudo systemctl start mariadb
              sudo systemctl enable mariadb
              sudo mysqladmin -u root password 'admin123'  # Set root password
              sudo mysql -u root -p'admin123' -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin123'"
              sudo mysql -u root -p'admin123' -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
              sudo mysql -u root -p'admin123' -e "DELETE FROM mysql.user WHERE User=''"
              sudo mysql -u root -p'admin123' -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
              sudo mysql -u root -p'admin123' -e "FLUSH PRIVILEGES"
              sudo mysql -u root -p'admin123' -e "CREATE DATABASE accounts"
              sudo mysql -u root -p'admin123' -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%' IDENTIFIED BY 'admin123'"
              sudo mkdir -p /tmp
              sudo git clone https://github.com/Mkhwanazi-B/proton.git -b awsliftandshift /tmp/vprofile-project
              sudo mysql -u root -p'admin123' accounts < /tmp/vprofile-project/src/main/resources/db_backup.sql
              sudo mysql -u root -p'admin123' -e "FLUSH PRIVILEGES"
              sudo systemctl restart mariadb
              EOF
  )

  tags = merge(local.tags, { Name = "vprofile-mysql" })  # Specific instance tag
}

# Memcached Instance resource
# Deploys a Memcached server with custom configuration
resource "aws_instance" "memcached" {
  ami           = var.ami_id            # Use Ubuntu AMI
  instance_type = "t3.micro"            # Free-tier eligible
  key_name      = var.key_name          # Existing key pair
  subnet_id     = element(var.subnet_ids, 1)  # Second public subnet
  associate_public_ip_address = true    # Public IP for testing
  security_groups = [var.security_group_id]  # Apply support SG

  # User data to install and configure Memcached
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e  # Exit on error
              sudo apt update
              sudo apt install memcached -y
              sudo sed -i 's/-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf  # Allow external access
              sudo systemctl start memcached
              sudo systemctl enable memcached
              sudo memcached -p 11211 -U 11111 -u memcached -d  # Run as daemon
              EOF
  )

  tags = merge(local.tags, { Name = "vprofile-memcached" })  # Specific instance tag
}

# RabbitMQ Instance resource
# Deploys a RabbitMQ server with user and permissions setup
resource "aws_instance" "rabbitmq" {
  ami           = var.ami_id            # Use Ubuntu AMI
  instance_type = "t3.micro"            # Free-tier eligible
  key_name      = var.key_name          # Existing key pair
  subnet_id     = element(var.subnet_ids, 2)  # Third public subnet
  associate_public_ip_address = true    # Public IP for testing
  security_groups = [var.security_group_id]  # Apply support SG

  # User data to install and configure RabbitMQ
  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e  # Exit on error
              sudo apt update
              sudo apt install -y erlang rabbitmq-server
              sudo systemctl start rabbitmq-server
              sudo systemctl enable rabbitmq-server
              sudo sh -c 'echo "[{rabbit, [{loopback_users, []}]}]." > /etc/rabbitmq/rabbitmq.config'  # Allow remote access
              sudo rabbitmqctl add_user test test  # Add test user
              sudo rabbitmqctl set_user_tags test administrator  # Grant admin rights
              sudo rabbitmqctl set_permissions -p / test ".*" ".*" ".*"  # Full permissions
              sudo systemctl restart rabbitmq-server
              EOF
  )

  tags = merge(local.tags, { Name = "vprofile-rabbitmq" })  # Specific instance tag
}

# Route 53 A Record for MySQL
resource "aws_route53_record" "db01" {
  zone_id = var.route53_zone_id  # Reference the private hosted zone
  name    = "db01.vprofile.ini"  # DNS record name
  type    = "A"                  # A record type
  ttl     = "300"                # Time to live in seconds
  records = [aws_instance.mysql.private_ip]  # Map to MySQL private IP
}

# Route 53 A Record for Memcached
resource "aws_route53_record" "mc01" {
  zone_id = var.route53_zone_id  # Reference the private hosted zone
  name    = "mc01.vprofile.ini"  # DNS record name
  type    = "A"                  # A record type
  ttl     = "300"                # Time to live in seconds
  records = [aws_instance.memcached.private_ip]  # Map to Memcached private IP
}

# Route 53 A Record for RabbitMQ
resource "aws_route53_record" "rmq01" {
  zone_id = var.route53_zone_id  # Reference the private hosted zone
  name    = "rmq01.vprofile.ini"  # DNS record name
  type    = "A"                  # A record type
  ttl     = "300"                # Time to live in seconds
  records = [aws_instance.rabbitmq.private_ip]  # Map to RabbitMQ private IP
}

# Variables passed from the parent module
variable "ami_id" {
  description = "AMI ID for instances"  # Base AMI for all instances
  type        = string
}

variable "key_name" {
  description = "Key pair name"  # SSH key for instance access
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for supporting instances"  # Network security
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs"  # Subnets for instance placement
  type        = list(string)
}

variable "route53_zone_id" {
  description = "Route 53 zone ID"  # Zone for DNS records
  type        = string
}

# Outputs to pass instance IPs to the parent module
output "db01_private_ip" {
  value = aws_instance.mysql.private_ip  # MySQL private IP
}

output "mc01_private_ip" {
  value = aws_instance.memcached.private_ip  # Memcached private IP
}

output "rmq01_private_ip" {
  value = aws_instance.rabbitmq.private_ip  # RabbitMQ private IP
}