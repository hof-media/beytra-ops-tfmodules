# VPC Network Module Outputs

output "network_id" {
  description = "VPC network ID"
  value       = google_compute_network.vpc.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc.self_link
}

output "subnets" {
  description = "Map of subnet names to subnet resources"
  value       = google_compute_subnetwork.subnets
}

output "cloud_nat_ips" {
  description = "List of static Cloud NAT IP addresses"
  value       = google_compute_address.nat_ips[*].address
}
