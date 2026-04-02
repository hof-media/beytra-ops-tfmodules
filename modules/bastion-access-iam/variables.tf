# Bastion Access IAM Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "service_account_email" {
  description = "Email of the service account to grant bastion access"
  type        = string
}

variable "grant_cloudsql_access" {
  description = "Whether to grant Cloud SQL Client role (needed if service account connects directly to Cloud SQL)"
  type        = bool
  default     = true
}
