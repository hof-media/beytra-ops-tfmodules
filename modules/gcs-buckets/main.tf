# GCS Buckets Module
# Creates course-specific buckets: {bucket_prefix}-{courseId}
# Default prefix: beytra-docs (document storage), also used for beytra-maps (map blobs)

locals {
  # Create a map of course buckets
  buckets = {
    for course_id in var.courses :
    course_id => {
      course_id = course_id
    }
  }
}

# Create GCS buckets (one per course)
resource "google_storage_bucket" "course_buckets" {
  for_each = local.buckets

  name                        = "${var.bucket_prefix}-${each.key}"
  location                    = var.region
  project                     = var.project_id
  storage_class               = var.storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Lifecycle rule for outbound folder only (skipped when retention_days = 0)
  dynamic "lifecycle_rule" {
    for_each = var.outbound_retention_days > 0 ? [1] : []
    content {
      action {
        type = "Delete"
      }
      condition {
        age            = var.outbound_retention_days
        matches_prefix = ["outbound/"]
      }
    }
  }

  # Labels
  labels = merge(var.labels, {
    course_id = each.key
    managed   = "terraform"
  })

  # CORS configuration for signed URL frontend access
  dynamic "cors" {
    for_each = length(var.cors_origins) > 0 ? [1] : []
    content {
      origin          = var.cors_origins
      method          = ["GET", "HEAD"]
      response_header = ["Content-Type", "Content-Length", "Content-Disposition"]
      max_age_seconds = 3600
    }
  }

  # Prevent accidental deletion
  force_destroy = var.force_destroy

  # Prevent deletion via Terraform
  lifecycle {
    prevent_destroy = true
  }
}

# IAM binding for service account
resource "google_storage_bucket_iam_member" "bucket_access" {
  for_each = local.buckets

  bucket = google_storage_bucket.course_buckets[each.key].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.service_account_email}"

  depends_on = [google_storage_bucket.course_buckets]
}

# Bucket notifications to Pub/Sub (triggers on file upload to /inbound/)
resource "google_storage_notification" "bucket_notification" {
  for_each = var.pubsub_topic_id != "" ? local.buckets : {}

  bucket         = google_storage_bucket.course_buckets[each.key].name
  payload_format = "JSON_API_V1"
  topic          = var.pubsub_topic_id
  event_types    = ["OBJECT_FINALIZE"]

  # Only trigger on /inbound/ uploads
  object_name_prefix = "inbound/"

  depends_on = [google_storage_bucket.course_buckets]
}
