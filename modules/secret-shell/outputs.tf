output "secret_id" {
  description = "The secret ID"
  value       = google_secret_manager_secret.secret.secret_id
}

output "secret_name" {
  description = "The fully qualified secret name"
  value       = google_secret_manager_secret.secret.name
}

output "populate_command" {
  description = "gcloud command to populate the secret value"
  value       = "gcloud secrets versions add ${var.secret_id} --project=${var.project_id} --data-file=secrets.json"
}

output "required_fields" {
  description = "Expected fields in the secret JSON"
  value       = var.required_fields
}
