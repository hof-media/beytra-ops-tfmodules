# CloudSQL PostgreSQL Instance Module
# Manages CloudSQL instance, users, and networking
# NOTE: Databases are NOT created here - they are created via Flyway migrations

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Generate secure password for beytra_user
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# CloudSQL PostgreSQL Instance
resource "google_sql_database_instance" "main" {
  name             = "beytra-${var.environment}"
  database_version = "POSTGRES_15"
  region           = var.region
  project          = var.project_id

  settings {
    tier                  = var.tier
    disk_type             = "PD_SSD"
    disk_size             = var.disk_size
    disk_autoresize       = true
    disk_autoresize_limit = var.disk_autoresize_limit
    availability_type     = var.availability_type

    backup_configuration {
      enabled                        = true
      start_time                     = "03:00"
      point_in_time_recovery_enabled = false
      transaction_log_retention_days = 1
      backup_retention_settings {
        retained_backups = var.backup_retained_count
      }
    }

    maintenance_window {
      day          = 7 # Sunday
      hour         = 3
      update_track = "stable"
    }

    ip_configuration {
      ipv4_enabled    = var.public_ip_enabled
      private_network = var.vpc_id

      dynamic "authorized_networks" {
        for_each = var.authorized_networks
        content {
          name  = authorized_networks.value.name
          value = authorized_networks.value.cidr
        }
      }
    }

    database_flags {
      name  = "max_connections"
      value = var.max_connections
    }

    user_labels = var.labels
  }

  deletion_protection = var.deletion_protection
}

# Create beytra_user (main database user)
resource "google_sql_user" "beytra_user" {
  name     = "beytra_user"
  instance = google_sql_database_instance.main.name
  password = random_password.db_password.result
  project  = var.project_id
}

# NOTE: Databases are NOT created here!
# They are created via Flyway migrations in beytra-db repository:
# - Migrations/beytra/V1__init_databases.sql creates:
#   - beytra-docs
#   - beytra-courses
#   - beytra-sms
#   - beytra-identity
#
# This keeps all database logic version-controlled in the beytra-db repository
# and works identically for local development and cloud deployment.
