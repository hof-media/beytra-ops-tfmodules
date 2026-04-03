variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "account_id" {
  description = "Service account ID (max 30 chars, e.g., 'beytra-api-courses')"
  type        = string
}

variable "display_name" {
  description = "Human-readable display name for the service account"
  type        = string
}

variable "description" {
  description = "Description of the service account's purpose"
  type        = string
  default     = ""
}

variable "preset" {
  description = "Permission preset: 'terraform' (plan/apply infra), 'deployer' (CI/CD app deploy), or null (use custom_role_permissions)"
  type        = string
  default     = null

  validation {
    condition     = var.preset == null || contains(["terraform", "deployer"], var.preset)
    error_message = "preset must be 'terraform', 'deployer', or null"
  }
}

variable "custom_role_permissions" {
  description = "List of GCP permissions for a custom least-privilege role. Merged with preset permissions if preset is set."
  type        = list(string)
  default     = []
}

variable "predefined_roles" {
  description = "Predefined GCP roles to bind (only for roles that can't be replicated as custom, e.g., 'roles/cloudsql.client')"
  type        = list(string)
  default     = []
}

variable "create_key" {
  description = "Create a service account key (DISCOURAGED — use Workload Identity instead)"
  type        = bool
  default     = false
}

variable "github_repo" {
  description = "GitHub repo for Workload Identity Federation (e.g., 'hof-media/beytra-api-courses'). Set to null to disable."
  type        = string
  default     = null
}

variable "workload_identity_pool" {
  description = "Workload Identity Pool ID for GitHub Actions OIDC (required if github_repo is set)"
  type        = string
  default     = ""
}

variable "impersonators" {
  description = "Service account emails allowed to impersonate (act as) this SA"
  type        = list(string)
  default     = []
}
