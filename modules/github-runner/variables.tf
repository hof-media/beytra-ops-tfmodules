variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for runner VMs"
  type        = string
  default     = "us-central1-a"
}

variable "network_id" {
  description = "VPC network ID for runner VMs"
  type        = string
}

variable "subnet_id" {
  description = "VPC subnet ID for runner VMs"
  type        = string
}

variable "runner_name_prefix" {
  description = "Prefix for runner VM names"
  type        = string
  default     = "github-runner"
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "e2-medium" # 2 vCPU, 4 GB RAM - good for docker-compose
}

variable "disk_size_gb" {
  description = "Boot disk size in GB"
  type        = number
  default     = 30
}

variable "github_org" {
  description = "GitHub organization name"
  type        = string
}

variable "github_repos" {
  description = "List of GitHub repos this runner serves (e.g., ['beytra-tests', 'beytra-db'])"
  type        = list(string)
}

variable "runner_labels" {
  description = "Labels for GitHub runner (e.g., ['self-hosted', 'beytra-dev', 'docker'])"
  type        = list(string)
  default     = ["self-hosted", "linux", "x64"]
}

variable "runner_service_account_email" {
  description = "Service account email for runner VMs"
  type        = string
}

variable "webhook_secret_name" {
  description = "Secret Manager secret name for GitHub webhook secret"
  type        = string
  default     = "github-webhook-secret"
}

variable "runner_token_secret_name" {
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

variable "runner_image" {
  description = "Custom runner image (e.g., gcr.io/beytra-dev/gh-runner:latest). If empty, uses Ubuntu base image."
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
