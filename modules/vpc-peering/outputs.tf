# VPC Peering Module Outputs

output "ip_range_name" {
  description = "Name of the allocated IP address range"
  value       = google_compute_global_address.private_ip_range.name
}

output "ip_range_address" {
  description = "Allocated IP address"
  value       = google_compute_global_address.private_ip_range.address
}

output "peering_connection" {
  description = "VPC peering connection details"
  value       = google_service_networking_connection.private_vpc_connection
}
