resource "google_pubsub_topic" "topic" {
  name    = var.topic_name
  project = var.project_id
}

# Dead Letter Topic
resource "google_pubsub_topic" "dead_letter_topic" {
  count   = var.enable_dlq ? 1 : 0
  name    = var.dead_letter_topic_name
  project = var.project_id

  message_retention_duration = var.dlq_message_retention
}

# Dead Letter Subscription (pull-based for manual inspection)
resource "google_pubsub_subscription" "dead_letter_subscription" {
  count   = var.enable_dlq ? 1 : 0
  name    = var.dead_letter_subscription_name
  topic   = google_pubsub_topic.dead_letter_topic[0].id
  project = var.project_id

  message_retention_duration = var.dlq_message_retention
  ack_deadline_seconds       = var.dlq_ack_deadline

  # Never expire the DLQ subscription
  expiration_policy {
    ttl = ""
  }
}

# IAM: Grant Pub/Sub service account permission to publish to DLQ
resource "google_pubsub_topic_iam_member" "dlq_publisher" {
  count   = var.enable_dlq ? 1 : 0
  project = var.project_id
  topic   = google_pubsub_topic.dead_letter_topic[0].name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

# IAM: Grant Pub/Sub service account permission to subscribe to DLQ
resource "google_pubsub_subscription_iam_member" "dlq_subscriber" {
  count        = var.enable_dlq ? 1 : 0
  project      = var.project_id
  subscription = google_pubsub_subscription.dead_letter_subscription[0].name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:service-${var.project_number}@gcp-sa-pubsub.iam.gserviceaccount.com"
}

resource "google_pubsub_subscription" "push_subscription" {
  name    = var.subscription_name
  topic   = google_pubsub_topic.topic.id
  project = var.project_id

  push_config {
    push_endpoint = var.push_endpoint

    oidc_token {
      service_account_email = var.service_account_email
    }

    attributes = {
      x-goog-version = "v1"
    }
  }

  retry_policy {
    minimum_backoff = var.min_backoff
    maximum_backoff = var.max_backoff
  }

  # DLQ Policy (conditionally added)
  dynamic "dead_letter_policy" {
    for_each = var.enable_dlq ? [1] : []
    content {
      dead_letter_topic     = google_pubsub_topic.dead_letter_topic[0].id
      max_delivery_attempts = var.max_delivery_attempts
    }
  }

  expiration_policy {
    ttl = "" # Never expire the subscription itself
  }

  message_retention_duration = "600s" # Only keep unacked messages for 10 minutes

  ack_deadline_seconds = var.ack_deadline
}
