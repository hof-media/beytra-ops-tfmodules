# VPC Peering Module for Google-managed services (CloudSQL, etc.)
# Allocates IP range and creates VPC peering connection

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Allocate IP address range for Google-managed services
resource "google_compute_global_address" "private_ip_range" {
  name          = var.address_name
  project       = var.project_id
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = var.prefix_length
  network       = var.network_id
  description   = var.description
}

# Create VPC peering connection to Google services
resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = var.network_id
  service                 = var.service
  reserved_peering_ranges = [google_compute_global_address.private_ip_range.name]

  depends_on = [google_compute_global_address.private_ip_range]
}
