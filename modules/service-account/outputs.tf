output "email" {
  description = "Service account email"
  value       = google_service_account.sa.email
}

output "name" {
  description = "Service account fully qualified name"
  value       = google_service_account.sa.name
}

output "id" {
  description = "Service account unique ID"
  value       = google_service_account.sa.unique_id
}

output "custom_role_id" {
  description = "Custom IAM role ID (null if no custom permissions)"
  value       = length(var.custom_role_permissions) > 0 ? google_project_iam_custom_role.role[0].id : null
}

output "key" {
  description = "Service account key (base64-encoded, null if create_key=false)"
  value       = var.create_key ? google_service_account_key.key[0].private_key : null
  sensitive   = true
}
