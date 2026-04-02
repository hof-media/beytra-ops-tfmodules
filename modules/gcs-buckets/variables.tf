variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "bucket_prefix" {
  description = "Prefix for bucket names (e.g., beytra-etl, beytra-maps)"
  type        = string
  default     = "beytra-docs"
}

variable "region" {
  description = "GCP region for buckets"
  type        = string
  default     = "us-central1"
}

variable "courses" {
  description = "List of course IDs to create buckets for"
  type        = list(string)
}

variable "storage_class" {
  description = "Storage class for buckets (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "outbound_retention_days" {
  description = "Number of days to retain files in outbound buckets before deletion"
  type        = number
  default     = 90
}

variable "service_account_email" {
  description = "Service account email to grant bucket access"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels to apply to all buckets"
  type        = map(string)
  default     = {}
}

variable "force_destroy" {
  description = "Allow deletion of non-empty buckets (use with caution)"
  type        = bool
  default     = false
}

variable "pubsub_topic_id" {
  description = "Pub/Sub topic ID for bucket notifications (leave empty to disable notifications)"
  type        = string
  default     = ""
}

variable "cors_origins" {
  description = "Allowed CORS origins for bucket access (for signed URL frontend access)"
  type        = list(string)
  default     = []
}
