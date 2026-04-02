output "redis_host" {
  description = "Redis instance host IP address"
  value       = google_redis_instance.cache.host
}

output "redis_port" {
  description = "Redis instance port"
  value       = google_redis_instance.cache.port
}

output "redis_connection_secret_id" {
  description = "Secret Manager secret ID containing Redis connection info"
  value       = google_secret_manager_secret.redis_connection.secret_id
}

output "redis_instance_id" {
  description = "Redis instance full resource ID"
  value       = google_redis_instance.cache.id
}
