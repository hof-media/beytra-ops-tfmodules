# VPC Network Module
# Creates VPC network with optional subnets

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_compute_network" "vpc" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = var.auto_create_subnetworks
  routing_mode            = var.routing_mode
  description             = var.description
}

# Custom subnets (only created if auto_create_subnetworks = false)
resource "google_compute_subnetwork" "subnets" {
  for_each = var.auto_create_subnetworks ? {} : var.subnets

  name          = each.key
  project       = var.project_id
  region        = each.value.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = each.value.ip_cidr_range
  description   = each.value.description

  # Private Google Access (allows access to Google APIs without public IP)
  private_ip_google_access = lookup(each.value, "private_ip_google_access", true)
}

# Cloud Router for Cloud NAT
resource "google_compute_router" "router" {
  count = var.enable_cloud_nat ? 1 : 0

  name    = var.cloud_nat_router_name != null ? var.cloud_nat_router_name : "${var.network_name}-nat-router"
  project = var.project_id
  region  = var.cloud_nat_region
  network = google_compute_network.vpc.id

  description = "Cloud Router for Cloud NAT - supports both VM and serverless endpoints"
}

# Static NAT IPs - used for Cloud Armor whitelisting
resource "google_compute_address" "nat_ips" {
  count = var.enable_cloud_nat ? var.cloud_nat_ip_count : 0

  name         = "${var.network_name}-nat-ip-${count.index}"
  project      = var.project_id
  region       = var.cloud_nat_region
  address_type = "EXTERNAL"

  description = "Static NAT IP ${count.index} for ${var.network_name}"
}

# Cloud NAT - enables outbound internet access for private resources
resource "google_compute_router_nat" "nat" {
  count = var.enable_cloud_nat ? 1 : 0

  name    = var.cloud_nat_name != null ? var.cloud_nat_name : "${var.network_name}-nat"
  project = var.project_id
  region  = var.cloud_nat_region
  router  = google_compute_router.router[0].name

  # Use static NAT IPs
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips                = google_compute_address.nat_ips[*].self_link

  # Apply to all subnetworks
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  # Support both VMs and serverless endpoints (Cloud Run via VPC Connector)
  endpoint_types = [
    "ENDPOINT_TYPE_VM",
    "ENDPOINT_TYPE_SWG" # Serverless to VPC Gateway
  ]

  # Enable endpoint-independent mapping for serverless
  enable_endpoint_independent_mapping = true

  # Logging configuration
  log_config {
    enable = var.cloud_nat_logging_enabled
    filter = var.cloud_nat_logging_filter
  }
}
