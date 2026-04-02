variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "gh_runner_name_prefix" {
  description = "Prefix for GitHub runner job names"
  type        = string
  default     = "github-runner"
}

variable "gh_runner_image" {
  description = "Container image for GitHub runner (e.g., gcr.io/beytra-dev/gh-runner:cloudrun-latest)"
  type        = string
}

variable "cpu_limit" {
  description = "CPU limit for Cloud Run Job"
  type        = string
  default     = "4"
}

variable "memory_limit" {
  description = "Memory limit for Cloud Run Job"
  type        = string
  default     = "8Gi"
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repos" {
  description = "List of GitHub repos this runner serves (e.g., ['beytra-tests', 'beytra-db'])"
  type        = list(string)
}

variable "gh_runner_labels" {
  description = "Labels for GitHub runner (e.g., ['self-hosted', 'beytra-dev', 'docker'])"
  type        = list(string)
  default     = ["self-hosted", "linux", "x64"]
}

variable "gh_runner_service_account_email" {
  description = "Service account email for GitHub runner jobs"
  type        = string
}

variable "gh_runner_token_secret_name" {
  description = "Secret Manager secret name for GitHub App private key"
  type        = string
  default     = "github-runner-token"
}

variable "github_app_id" {
  description = "GitHub App ID for runner authentication"
  type        = string
}

variable "github_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpc_connector_id" {
  description = "Serverless VPC Access connector ID for Cloud SQL private IP access (e.g., projects/PROJECT/locations/REGION/connectors/CONNECTOR)"
  type        = string
}
