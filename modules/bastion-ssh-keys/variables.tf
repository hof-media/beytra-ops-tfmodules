# Bastion SSH Keys Module Variables

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "key_name" {
  description = "Base name for SSH key secrets (e.g., 'beytra-dev-bastion')"
  type        = string
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}
