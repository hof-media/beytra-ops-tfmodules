output "service_account_email" {
  description = "Email of the ETL service account"
  value       = google_service_account.etl_service_account.email
}

output "service_account_name" {
  description = "Name of the ETL service account"
  value       = google_service_account.etl_service_account.name
}

output "service_account_key" {
  description = "Service account key (base64 encoded, sensitive)"
  value       = var.create_service_account_key ? google_service_account_key.etl_key[0].private_key : null
  sensitive   = true
}

output "github_deploy_service_account_email" {
  description = "Email of the GitHub deploy service account"
  value       = var.create_github_deploy_sa ? google_service_account.github_deploy[0].email : null
}

output "github_deploy_service_account_name" {
  description = "Name of the GitHub deploy service account"
  value       = var.create_github_deploy_sa ? google_service_account.github_deploy[0].name : null
}

output "github_deploy_service_account_key" {
  description = "GitHub deploy service account key (base64 encoded, sensitive)"
  value       = var.create_github_deploy_sa && var.create_github_deploy_key ? google_service_account_key.github_deploy_key[0].private_key : null
  sensitive   = true
}

output "enabled_apis" {
  description = "List of enabled APIs"
  value       = [for api in google_project_service.required_apis : api.service]
}
