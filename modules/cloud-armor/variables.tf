variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "policy_name" {
  description = "Name of the Cloud Armor security policy"
  type        = string
}

variable "description" {
  description = "Description of the security policy"
  type        = string
  default     = "Cloud Armor security policy with deny-all default"
}

variable "enable_adaptive_protection" {
  description = "Enable adaptive protection for DDoS mitigation"
  type        = bool
  default     = false
}

variable "whitelisted_ips" {
  description = "List of IP ranges with full access to all backends (e.g., developer IPs)"
  type        = list(string)
  default     = []
}

variable "cloud_nat_ips" {
  description = "List of Cloud NAT IP addresses for host-restricted access (auth.beytra.dev, api.beytra.dev only)"
  type        = list(string)
  default     = []
}

variable "domain" {
  description = "Base domain for host-based filtering (e.g., beytra.dev)"
  type        = string
  default     = ""
}
