output "job_name" {
  description = "Name of the Cloud Run Job"
  value       = google_cloud_run_v2_job.migration_job.name
}

output "job_id" {
  description = "ID of the Cloud Run Job"
  value       = google_cloud_run_v2_job.migration_job.id
}
