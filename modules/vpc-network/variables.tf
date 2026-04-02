# VPC Network Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "auto_create_subnetworks" {
  description = "When true, creates one subnet per region automatically. When false, use custom subnets."
  type        = bool
  default     = true
}

variable "routing_mode" {
  description = "Network routing mode (REGIONAL or GLOBAL)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be either REGIONAL or GLOBAL"
  }
}

variable "description" {
  description = "VPC network description"
  type        = string
  default     = null
}

variable "subnets" {
  description = "Map of custom subnets (only used when auto_create_subnetworks = false)"
  type = map(object({
    region                   = string
    ip_cidr_range            = string
    description              = optional(string)
    private_ip_google_access = optional(bool, true)
  }))
  default = {}
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT for outbound internet access from private resources"
  type        = bool
  default     = false
}

variable "cloud_nat_region" {
  description = "Region for Cloud NAT router (required if enable_cloud_nat = true)"
  type        = string
  default     = null
}

variable "cloud_nat_router_name" {
  description = "Custom name for Cloud Router (defaults to <network_name>-nat-router)"
  type        = string
  default     = null
}

variable "cloud_nat_name" {
  description = "Custom name for Cloud NAT (defaults to <network_name>-nat)"
  type        = string
  default     = null
}

variable "cloud_nat_logging_enabled" {
  description = "Enable Cloud NAT logging"
  type        = bool
  default     = false
}

variable "cloud_nat_logging_filter" {
  description = "Cloud NAT logging filter (ERRORS_ONLY, TRANSLATIONS_ONLY, ALL)"
  type        = string
  default     = "ERRORS_ONLY"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.cloud_nat_logging_filter)
    error_message = "cloud_nat_logging_filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL"
  }
}

variable "cloud_nat_ip_count" {
  description = "Number of static NAT IPs to allocate (required if enable_cloud_nat = true). Recommended: 1 for dev, 2+ for prod."
  type        = number
  default     = 1
}
