# Secret Manager Module
# Creates and manages GCP secrets for application configuration

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "secret_id" {
  description = "Secret ID (e.g., 'beytra-etl-docs/dev')"
  type        = string
}

variable "secret_data" {
  description = "Secret data as JSON string"
  type        = string
  sensitive   = true
  default     = null
}

variable "replication_locations" {
  description = "Replication locations for secret (empty = automatic)"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to secret"
  type        = map(string)
  default     = {}
}

# Create secret
resource "google_secret_manager_secret" "secret" {
  project   = var.project_id
  secret_id = var.secret_id

  replication {
    auto {}
  }

  labels = var.labels
}

# Create secret version (only if secret_data is provided)
resource "google_secret_manager_secret_version" "secret_version" {
  count = var.secret_data != null ? 1 : 0

  secret      = google_secret_manager_secret.secret.id
  secret_data = var.secret_data

  lifecycle {
    ignore_changes = [secret_data]
  }
}

# Output secret details
output "secret_id" {
  description = "Full secret resource ID"
  value       = google_secret_manager_secret.secret.id
}

output "secret_name" {
  description = "Secret name (for secret_name parameter)"
  value       = google_secret_manager_secret.secret.secret_id
}

output "secret_path" {
  description = "Full secret path"
  value       = google_secret_manager_secret.secret.name
}
