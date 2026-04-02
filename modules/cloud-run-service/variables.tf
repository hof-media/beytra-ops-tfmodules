variable "service_name" {
  description = "Name of the Cloud Run service"
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
  description = "Container image URL"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for the Cloud Run service"
  type        = string
}

variable "min_instances" {
  description = "Minimum number of instances (warm pool)"
  type        = number
  default     = 0
}

variable "max_instances" {
  description = "Maximum number of instances"
  type        = number
  default     = 10
}

variable "max_concurrency" {
  description = "Maximum concurrent requests per instance"
  type        = number
  default     = 10
}

variable "cpu_limit" {
  description = "CPU limit per instance"
  type        = string
  default     = "4"
}

variable "memory_limit" {
  description = "Memory limit per instance"
  type        = string
  default     = "8Gi"
}

variable "timeout" {
  description = "Request timeout"
  type        = string
  default     = "3600s"
}

variable "env_vars" {
  description = "Environment variables for the container"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels to apply to the Cloud Run service"
  type        = map(string)
  default     = {}
}

variable "vpc_connector_id" {
  description = "Serverless VPC connector ID for private networking (optional)"
  type        = string
  default     = null
}

variable "ingress" {
  description = "Ingress settings for the service"
  type        = string
  default     = "INGRESS_TRAFFIC_INTERNAL_ONLY"
  validation {
    condition     = contains(["INGRESS_TRAFFIC_ALL", "INGRESS_TRAFFIC_INTERNAL_ONLY", "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"], var.ingress)
    error_message = "Ingress must be one of: INGRESS_TRAFFIC_ALL, INGRESS_TRAFFIC_INTERNAL_ONLY, INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER"
  }
}

variable "allow_unauthenticated" {
  description = "Allow unauthenticated access (allUsers)"
  type        = bool
  default     = false
}

variable "allowed_domain" {
  description = "Domain to allow access (e.g., 'hof.media'). Requires authentication."
  type        = string
  default     = null
}

variable "vpc_egress" {
  description = "VPC egress setting: ALL_TRAFFIC or PRIVATE_RANGES_ONLY"
  type        = string
  default     = "PRIVATE_RANGES_ONLY"
  validation {
    condition     = contains(["ALL_TRAFFIC", "PRIVATE_RANGES_ONLY"], var.vpc_egress)
    error_message = "VPC egress must be either ALL_TRAFFIC or PRIVATE_RANGES_ONLY"
  }
}

variable "secret_volumes" {
  description = "Secret volumes to mount as files in the container"
  type = list(object({
    name        = string # Volume name (used internally)
    secret_name = string # Secret Manager secret ID
    mount_path  = string # Path in container (e.g., /secrets/gcs-signer)
    file_name   = string # Filename inside mount_path (e.g., key.json)
  }))
  default = []
}

variable "container_command" {
  description = "Container entrypoint command (replaces default entrypoint)"
  type        = list(string)
  default     = null
}

variable "container_args" {
  description = "Container arguments (passed to entrypoint/command)"
  type        = list(string)
  default     = null
}

variable "container_port" {
  description = "Container port to expose"
  type        = number
  default     = 8080
}

variable "secret_env_vars" {
  description = "Environment variables sourced from Secret Manager secrets (raw values, Cloud Run fetches via secret_key_ref)"
  type = list(object({
    name        = string                     # Environment variable name (e.g., ZITADEL_MASTERKEY)
    secret_name = string                     # Secret Manager secret ID (e.g., beytra-api-zitadel-masterkey-dev)
    version     = optional(string, "latest") # Secret version
  }))
  default = []
}

variable "startup_probe_timeout" {
  description = "Startup probe timeout in seconds (for services that need longer init time like Zitadel)"
  type        = number
  default     = null # Use Cloud Run defaults when null
}

variable "additional_invokers" {
  description = "Additional IAM members allowed to invoke this service (e.g., ['serviceAccount:beytra-gateway@project.iam.gserviceaccount.com'])"
  type        = list(string)
  default     = []
}

#------------------------------------------------------------------------------
# Cost Optimization Variables
#------------------------------------------------------------------------------

variable "cpu_idle" {
  description = "CPU allocation mode: true = request-based billing (CPU only during requests), false = instance-based billing (CPU always allocated)"
  type        = bool
  default     = true # Request-based by default for cost savings
}

variable "startup_cpu_boost" {
  description = "Enable startup CPU boost for faster cold starts (recommended when cpu_idle=true and min_instances=0)"
  type        = bool
  default     = false # Disabled by default, enable per-service
}
