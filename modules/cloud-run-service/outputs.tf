output "service_uri" {
  description = "URI of the Cloud Run service"
  value       = google_cloud_run_v2_service.etl_processor.uri
}

output "service_name" {
  description = "Name of the Cloud Run service"
  value       = google_cloud_run_v2_service.etl_processor.name
}

output "service_id" {
  description = "Full resource ID of the Cloud Run service"
  value       = google_cloud_run_v2_service.etl_processor.id
}
