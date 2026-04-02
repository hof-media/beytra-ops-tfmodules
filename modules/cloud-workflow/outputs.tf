output "workflow_id" {
  description = "The ID of the workflow"
  value       = google_workflows_workflow.etl_trigger.id
}

output "workflow_name" {
  description = "The name of the workflow"
  value       = google_workflows_workflow.etl_trigger.name
}

output "trigger_id" {
  description = "The ID of the Eventarc trigger"
  value       = google_eventarc_trigger.gcs_trigger.id
}
