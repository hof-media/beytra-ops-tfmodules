variable "topic_name" {
  description = "Name of the Pub/Sub topic"
  type        = string
}

variable "subscription_name" {
  description = "Name of the Pub/Sub subscription"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "push_endpoint" {
  description = "HTTP endpoint to push messages to"
  type        = string
}

variable "service_account_email" {
  description = "Service account email for OIDC authentication"
  type        = string
}

variable "min_backoff" {
  description = "Minimum retry backoff"
  type        = string
  default     = "10s"
}

variable "max_backoff" {
  description = "Maximum retry backoff"
  type        = string
  default     = "600s"
}

variable "ack_deadline" {
  description = "Acknowledgement deadline in seconds"
  type        = number
  default     = 600
}

variable "max_delivery_attempts" {
  description = "Maximum number of delivery attempts before sending to dead letter queue"
  type        = number
  default     = 5

  validation {
    condition     = var.max_delivery_attempts >= 5 && var.max_delivery_attempts <= 100
    error_message = "max_delivery_attempts must be between 5 and 100 (GCP limits)"
  }
}

variable "enable_dlq" {
  description = "Enable dead letter queue for failed messages"
  type        = bool
  default     = false
}

variable "dead_letter_topic_name" {
  description = "Name of the dead letter topic (only used if enable_dlq=true)"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_dlq || var.dead_letter_topic_name != ""
    error_message = "dead_letter_topic_name must be provided when enable_dlq is true"
  }
}

variable "dead_letter_subscription_name" {
  description = "Name of the dead letter subscription (only used if enable_dlq=true)"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_dlq || var.dead_letter_subscription_name != ""
    error_message = "dead_letter_subscription_name must be provided when enable_dlq is true"
  }
}

variable "project_number" {
  description = "GCP project number (required for DLQ IAM)"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_dlq || var.project_number != ""
    error_message = "project_number must be provided when enable_dlq is true"
  }
}

variable "dlq_message_retention" {
  description = "Message retention duration for DLQ (default: 7 days)"
  type        = string
  default     = "604800s"
}

variable "dlq_ack_deadline" {
  description = "Acknowledgement deadline for DLQ subscription in seconds (default: 600)"
  type        = number
  default     = 600

  validation {
    condition     = var.dlq_ack_deadline >= 10 && var.dlq_ack_deadline <= 600
    error_message = "dlq_ack_deadline must be between 10 and 600 seconds (GCP limits)"
  }
}
