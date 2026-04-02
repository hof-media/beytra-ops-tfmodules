# Bastion Access IAM Module
# Grants a service account all permissions needed for bastion SSH access

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# IAP tunnel access (for TCP forwarding through Cloud IAP)
resource "google_project_iam_member" "iap_tunnel" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${var.service_account_email}"
}

# View compute resources (needed to resolve instance names)
resource "google_project_iam_member" "compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${var.service_account_email}"
}

# Cloud SQL Client (optional, for projects that need direct DB access)
resource "google_project_iam_member" "cloudsql_client" {
  count   = var.grant_cloudsql_access ? 1 : 0
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${var.service_account_email}"
}

# Secret Manager access (to read bastion SSH key)
resource "google_project_iam_member" "secretmanager_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${var.service_account_email}"
}
