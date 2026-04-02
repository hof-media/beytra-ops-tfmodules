variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "The project name for resource naming"
  type        = string
}

variable "project_number" {
  description = "The GCP project number (required for service agent permissions)"
  type        = string
}

variable "create_service_account_key" {
  description = "Whether to create a service account key for ETL pipeline"
  type        = bool
  default     = false
}

variable "etl_service_account_roles" {
  description = "IAM roles for the ETL service account"
  type        = list(string)
  default = [
    "roles/storage.objectAdmin" # Read/write access to GCS buckets
  ]
}

variable "create_github_deploy_sa" {
  description = "Whether to create a GitHub Actions deploy service account"
  type        = bool
  default     = false
}

variable "create_github_deploy_key" {
  description = "Whether to create a service account key for GitHub deploy"
  type        = bool
  default     = false
}

variable "github_deploy_roles" {
  description = "IAM roles for the GitHub deploy service account"
  type        = list(string)
  default = [
    "roles/artifactregistry.writer" # Write Docker images to Artifact Registry
  ]
}

variable "required_apis" {
  description = "List of APIs to enable for Beytra ETL"
  type        = list(string)
  default = [
    "storage.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "iam.googleapis.com",
    "containerregistry.googleapis.com",
    "artifactregistry.googleapis.com"
  ]
}
