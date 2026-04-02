resource "google_workflows_workflow" "etl_trigger" {
  name            = "beytra-docs-trigger-${replace(var.bucket_name, "beytra-docs-", "")}"
  region          = var.region
  project         = var.project_id
  service_account = var.service_account_email

  source_contents = templatefile("${path.module}/workflow.yaml", {
    pubsub_topic_id = var.pubsub_topic_id
  })

  labels = var.labels
}

# Eventarc trigger to invoke workflow on GCS uploads
resource "google_eventarc_trigger" "gcs_trigger" {
  name     = "beytra-docs-gcs-trigger-${replace(var.bucket_name, "beytra-docs-", "")}"
  location = var.region
  project  = var.project_id

  # Match GCS object finalize events
  matching_criteria {
    attribute = "type"
    value     = "google.cloud.storage.object.v1.finalized"
  }

  matching_criteria {
    attribute = "bucket"
    value     = var.bucket_name
  }

  # Trigger the workflow
  destination {
    workflow = google_workflows_workflow.etl_trigger.id
  }

  service_account = var.service_account_email

  labels = var.labels
}
