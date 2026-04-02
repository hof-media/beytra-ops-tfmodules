variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "secret_id" {
  description = "Secret Manager secret ID (e.g., 'beytra-api-courses-dev')"
  type        = string
}

variable "required_fields" {
  description = "List of expected fields in the secret JSON (for documentation only, not enforced)"
  type        = list(string)
  default     = []
}

variable "accessor_service_accounts" {
  description = "Service account emails that can read this secret"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to apply to the secret"
  type        = map(string)
  default     = {}
}
