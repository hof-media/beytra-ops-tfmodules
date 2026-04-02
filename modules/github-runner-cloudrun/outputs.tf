output "gh_runner_job_executor_url" {
  description = "URL of the GitHub runner job executor Cloud Function"
  value       = google_cloudfunctions2_function.gh_runner_job_executor.url
}

output "job_name" {
  description = "Name of the Cloud Run Job"
  value       = google_cloud_run_v2_job.github_runner.name
}

output "function_service_account_email" {
  description = "Email of the function service account"
  value       = google_service_account.function_sa.email
}

# OIDC / Workload Identity outputs for GitHub Actions
output "github_workload_identity_provider" {
  description = "Workload Identity Provider for GitHub Actions OIDC (use in GitHub workflow)"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "github_service_account_email" {
  description = "Service account email for GitHub Actions to impersonate"
  value       = google_service_account.github_actions_invoker.email
}

output "workload_identity_pool_id" {
  description = "Workload Identity Pool ID"
  value       = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
}
