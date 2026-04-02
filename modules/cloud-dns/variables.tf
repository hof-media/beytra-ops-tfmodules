variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "zone_name" {
  description = "Name for the DNS zone resource (e.g., 'beytra-dev')"
  type        = string
}

variable "domain" {
  description = "Domain name without trailing dot (e.g., 'beytra.dev')"
  type        = string
}

variable "load_balancer_ip" {
  description = "Static IP address of the load balancer"
  type        = string
}

variable "subdomains" {
  description = "Map of subdomain names to create A records for (e.g., { 'api' = {}, 'hooks' = {} })"
  type        = map(object({}))
  default     = {}
}

variable "create_root_record" {
  description = "Create an A record for the root domain"
  type        = bool
  default     = false
}

variable "record_ttl" {
  description = "TTL for DNS records in seconds"
  type        = number
  default     = 300
}

variable "enable_dnssec" {
  description = "Enable DNSSEC for the zone"
  type        = bool
  default     = false
}

variable "labels" {
  description = "Labels to apply to the DNS zone"
  type        = map(string)
  default     = {}
}
