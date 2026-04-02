# VPC Peering Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "network_id" {
  description = "VPC network ID to peer with Google services"
  type        = string
}

variable "address_name" {
  description = "Name for the allocated IP address range"
  type        = string
}

variable "prefix_length" {
  description = "Prefix length for the IP address range (e.g., 16 for /16)"
  type        = number
  default     = 16
}

variable "service" {
  description = "Google service to peer with"
  type        = string
  default     = "servicenetworking.googleapis.com"
}

variable "description" {
  description = "Description for the IP address range"
  type        = string
  default     = "IP range for Google-managed services VPC peering"
}
