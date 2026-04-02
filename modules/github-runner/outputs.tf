output "webhook_url" {
  description = "Cloud Function webhook URL (configure in GitHub)"
  value       = google_cloudfunctions2_function.webhook_receiver.service_config[0].uri
}

output "function_service_account" {
  description = "Service account email for Cloud Function"
  value       = google_service_account.function_sa.email
}

output "instance_template_name" {
  description = "Compute Engine instance template name"
  value       = google_compute_instance_template.runner.name
}
