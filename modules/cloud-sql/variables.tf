# CloudSQL Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for CloudSQL instance"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tier" {
  description = "CloudSQL machine tier (e.g., db-f1-micro, db-n1-standard-1)"
  type        = string
  default     = "db-f1-micro"
}

variable "disk_size" {
  description = "Initial disk size in GB"
  type        = number
  default     = 10
}

variable "disk_autoresize_limit" {
  description = "Maximum disk size for autoresize in GB"
  type        = number
  default     = 50
}

variable "availability_type" {
  description = "Availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"

  validation {
    condition     = contains(["ZONAL", "REGIONAL"], var.availability_type)
    error_message = "availability_type must be either ZONAL or REGIONAL"
  }
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = false
}

variable "public_ip_enabled" {
  description = "Enable public IP address"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC network ID for private IP (optional)"
  type        = string
  default     = null
}

variable "authorized_networks" {
  description = "List of authorized networks for public IP access"
  type = list(object({
    name = string
    cidr = string
  }))
  default = []
}

variable "max_connections" {
  description = "Maximum number of connections"
  type        = string
  default     = "100"
}

variable "backup_retained_count" {
  description = "Number of backups to retain"
  type        = number
  default     = 7
}

variable "labels" {
  description = "Resource labels"
  type        = map(string)
  default     = {}
}

variable "users" {
  description = "Map of DB users to create. Each entry gets a random_password + Secret Manager secret (beytra-db-password-{environment}-{user}). Key = DB username, value.databases = list of logical DBs the user serves (documentation only; grants are not auto-created here)."
  type = map(object({
    databases = list(string)
  }))
  default = {
    beytra = {
      databases = ["beytra-docs", "beytra-courses", "beytra-sms", "beytra-identity", "beytra-zitadel"]
    }
  }
}

variable "secret_accessor_service_accounts" {
  description = "Service account emails granted secretAccessor on ALL per-user DB password secrets. Leave empty to manage access per-app via data sources in each app's .iac/."
  type        = list(string)
  default     = []
}
