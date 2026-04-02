variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region for the workflow"
  type        = string
}

variable "bucket_name" {
  description = "The GCS bucket name to watch for uploads"
  type        = string
}

variable "pubsub_topic_id" {
  description = "The Pub/Sub topic ID to publish messages to"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for workflow execution"
  type        = string
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
