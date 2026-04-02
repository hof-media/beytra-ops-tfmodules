/**
 * Cloud Memorystore Redis Module
 *
 * Creates a Redis instance for caching, sessions, and job queues.
 * Supports both BASIC (single node) and STANDARD_HA (with replica) tiers.
 */

resource "google_redis_instance" "cache" {
  name               = var.instance_name
  project            = var.project_id
  region             = var.region
  tier               = var.tier
  memory_size_gb     = var.memory_size_gb
  redis_version      = var.redis_version

  authorized_network = var.vpc_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"

  # Standard tier: HA with read replicas
  replica_count = var.tier == "STANDARD_HA" ? 1 : 0

  maintenance_policy {
    weekly_maintenance_window {
      day = "SUNDAY"
      start_time {
        hours   = 3
        minutes = 0
      }
    }
  }

  labels = var.labels
}

# Store connection info in Secret Manager
resource "google_secret_manager_secret" "redis_connection" {
  project   = var.project_id
  secret_id = "${var.instance_name}-connection"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "redis_connection_version" {
  secret = google_secret_manager_secret.redis_connection.id

  secret_data = jsonencode({
    CANVAS_REDIS_HOST = google_redis_instance.cache.host
    REDIS_PORT        = tostring(google_redis_instance.cache.port)
  })
}
