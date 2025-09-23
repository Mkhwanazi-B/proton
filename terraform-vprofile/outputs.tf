# Define outputs to expose key resource information after deployment
# Useful for post-deployment configuration (e.g., DNS updates)
output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer" # For CNAME record in GoDaddy
  value       = module.alb.alb_dns_name
}

output "db01_ip" {
  description = "Private IP of the MySQL instance" # For internal app connectivity
  value       = module.supporting_instances.db01_private_ip
}

output "mc01_ip" {
  description = "Private IP of the Memcached instance" # For caching layer
  value       = module.supporting_instances.mc01_private_ip
}

output "rmq01_ip" {
  description = "Private IP of the RabbitMQ instance" # For message queuing
  value       = module.supporting_instances.rmq01_private_ip
}

output "route53_zone_id" {
  description = "ID of the Route 53 private hosted zone" # For DNS record management
  value       = data.aws_route53_zone.vprofile_zone.zone_id
}