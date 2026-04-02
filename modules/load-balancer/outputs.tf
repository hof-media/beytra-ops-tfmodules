output "ip_address" {
  description = "Static IP address of the load balancer"
  value       = google_compute_global_address.main.address
}

output "ip_name" {
  description = "Name of the static IP address resource"
  value       = google_compute_global_address.main.name
}

output "url_map_id" {
  description = "ID of the URL map"
  value       = google_compute_url_map.main.id
}

output "ssl_certificate_ids" {
  description = "Map of SSL certificate IDs by domain"
  value = {
    for domain, cert in google_compute_managed_ssl_certificate.domain :
    domain => cert.id
  }
}

output "backend_service_ids" {
  description = "Map of Cloud Run backend service IDs"
  value = {
    for key, backend in google_compute_backend_service.cloudrun :
    key => backend.id
  }
}

output "backend_bucket_ids" {
  description = "Map of GCS backend bucket IDs"
  value = {
    for key, bucket in google_compute_backend_bucket.gcs :
    key => bucket.id
  }
}
