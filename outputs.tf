#
# Output the information required to test the
# environment created in main.tf
#
# - Username for instance
# - Public IP address for instance
# - SSH key name (for instance login)
#
output "username" {
  description = "Username for instance login (all instances)"
  value       = "root"
}

output "public_ip_frontend_a" {
  description = "Instance A public IP address"
  value       = "${alicloud_instance.tf-demo-frontend-ecs-A.public_ip}"
}

output "public_ip_frontend_b" {
  description = "Instance B public IP address"
  value       = "${alicloud_instance.tf-demo-frontend-ecs-B.public_ip}"
}

output "private_ip_backend_a" {
  description = "Instance A private IP address"
  value       = "${alicloud_instance.tf-demo-backend-ecs-A.private_ip}"
}

output "private_ip_backend_b" {
  description = "Instance B private IP address"
  value       = "${alicloud_instance.tf-demo-backend-ecs-B.private_ip}"
}

output "frontend_load_balancer" {
  description = "External Server Load Balancer IP address"
  value       = "${alicloud_eip.tf-demo-eip-frontend-slb.ip_address}"
}

output "backend_load_balancer" {
  description = "Internal Server Load Balancer IP address"
  value       = "${alicloud_slb.tf-demo-slb-backend.address}"
}

output "ssh_key_file" {
  description = "Name of SSH key for instance login"
  value = "${var.ssh_key_name}.pem"
}