# Serverless VPC Connector Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the connector"
  type        = string
}

variable "connector_name" {
  description = "Name of the VPC connector"
  type        = string
}

variable "network_id" {
  description = "VPC network ID"
  type        = string
}

variable "ip_cidr_range" {
  description = "CIDR range for the connector (e.g., 10.8.0.0/28). Only used if subnet_name is null."
  type        = string
  default     = "10.8.0.0/28"
}

variable "subnet_name" {
  description = "Name of existing subnet to use (optional, overrides ip_cidr_range)"
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Machine type for connector instances"
  type        = string
  default     = "e2-micro"
}

variable "min_instances" {
  description = "Minimum number of connector instances"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "Maximum number of connector instances"
  type        = number
  default     = 3
}
