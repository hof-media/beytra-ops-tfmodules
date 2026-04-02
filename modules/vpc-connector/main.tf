# Serverless VPC Connector Module
# Allows Cloud Run and Cloud Functions to access VPC resources

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_vpc_access_connector" "connector" {
  name    = var.connector_name
  project = var.project_id
  region  = var.region

  # Subnet configuration (either subnet or ip_cidr_range, not both)
  dynamic "subnet" {
    for_each = var.subnet_name != null ? [1] : []
    content {
      name       = var.subnet_name
      project_id = var.project_id
    }
  }

  # IP CIDR range (only if subnet is not specified)
  ip_cidr_range = var.subnet_name == null ? var.ip_cidr_range : null

  # Network
  network = var.network_id

  # Machine type and scaling
  machine_type  = var.machine_type
  min_instances = var.min_instances
  max_instances = var.max_instances

  # Min throughput is deprecated, using min_instances instead
}
