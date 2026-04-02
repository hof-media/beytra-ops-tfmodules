variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for VPN gateway"
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network to attach VPN gateway to"
  type        = string
}

variable "gateway_name" {
  description = "Name of the VPN gateway"
  type        = string
}

variable "peer_external_gateway_ip" {
  description = "Public IP address of your local router/firewall"
  type        = string
}

variable "shared_secret" {
  description = "Pre-shared key for VPN tunnel"
  type        = string
  sensitive   = true
}

variable "vpn_local_network_cidrs" {
  description = "CIDR ranges of your local network"
  type        = list(string)
  default     = ["192.168.0.0/24"]
}
