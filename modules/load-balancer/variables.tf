variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "name" {
  description = "Base name for all load balancer resources"
  type        = string
}

variable "ssl_domains" {
  description = "List of domains for the SSL certificate (e.g., ['*.beytra.dev', 'beytra.dev'])"
  type        = list(string)
}

variable "security_policy_self_link" {
  description = "Self-link of the Cloud Armor security policy to attach to backends"
  type        = string
  default     = null
}

# GCS backend configurations
variable "gcs_backends" {
  description = "Map of GCS bucket backends"
  type = map(object({
    bucket_name    = string
    enable_cdn     = optional(bool, false)
    custom_headers = optional(list(string), null)
  }))
  default = {}
}

# Cloud Run backend configurations
variable "cloudrun_backends" {
  description = "Map of Cloud Run service backends"
  type = map(object({
    service_name = string
    region       = string
  }))
  default = {}
}

# Host-based routing rules
variable "host_rules" {
  description = "Map of host rules for URL routing"
  type = map(object({
    hosts              = list(string)
    backend_type       = string                 # "cloudrun" or "gcs"
    backend_key        = string                 # Key in cloudrun_backends or gcs_backends
    root_redirect_path = optional(string, null) # Redirect "/" to this path (e.g., "/storybook/latest/index.html")
    path_rules = optional(list(object({
      paths        = list(string)
      backend_type = string
      backend_key  = string
    })), null)
  }))
}

# Default backend for unmatched requests
variable "default_backend_type" {
  description = "Type of default backend: 'cloudrun' or 'gcs'"
  type        = string
  default     = "cloudrun"
}

variable "default_backend_key" {
  description = "Key of the default backend in cloudrun_backends or gcs_backends"
  type        = string
}

variable "enable_http_redirect" {
  description = "Enable HTTP to HTTPS redirect"
  type        = bool
  default     = true
}
