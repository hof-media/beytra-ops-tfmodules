# Cloud Run Job for Database Migrations
# Runs Flyway migrations with VPC access to private CloudSQL

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_cloud_run_v2_job" "migration_job" {
  name     = var.job_name
  location = var.region
  project  = var.project_id

  template {
    template {
      service_account = var.service_account_email
      max_retries     = 0 # Fail fast, don't retry

      dynamic "vpc_access" {
        for_each = var.vpc_connector_id != null ? [1] : []
        content {
          connector = var.vpc_connector_id
          egress    = var.vpc_egress
        }
      }

      containers {
        image = var.container_image

        env {
          name  = "GOOGLE_PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "ENVIRONMENT"
          value = var.environment
        }

        env {
          name  = "MIGRATION_PATH"
          value = var.migration_path
        }

        resources {
          limits = {
            cpu    = var.cpu_limit
            memory = var.memory_limit
          }
        }

        dynamic "volume_mounts" {
          for_each = length(var.cloudsql_instances) > 0 ? [1] : []
          content {
            name       = "cloudsql"
            mount_path = "/cloudsql"
          }
        }
      }

      dynamic "volumes" {
        for_each = var.cloudsql_instances
        content {
          name = "cloudsql"
          cloud_sql_instance {
            instances = [volumes.value]
          }
        }
      }

      timeout = var.timeout
    }
  }

  labels = var.labels
}
