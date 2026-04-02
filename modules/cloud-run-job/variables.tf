variable "job_name" {
  description = "Name of the Cloud Run Job"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "container_image" {
  description = "Container image for the job"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the job"
  type        = string
}

variable "vpc_connector_id" {
  description = "VPC connector ID for private network access"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "migration_path" {
  description = "Migration path (beytra, beytra-docs, etc.)"
  type        = string
}

variable "cpu_limit" {
  description = "CPU limit"
  type        = string
  default     = "1"
}

variable "memory_limit" {
  description = "Memory limit"
  type        = string
  default     = "512Mi"
}

variable "timeout" {
  description = "Job timeout"
  type        = string
  default     = "600s"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "cloudsql_instances" {
  description = "CloudSQL instances to connect to (for built-in Cloud Run CloudSQL integration)"
  type        = list(string)
  default     = []
}

variable "vpc_egress" {
  description = "VPC egress setting (PRIVATE_RANGES_ONLY or ALL_TRAFFIC)"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
}
