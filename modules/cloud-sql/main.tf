# CloudSQL PostgreSQL Instance Module
# Manages CloudSQL instance, users, and per-user Secret Manager password secrets.
# NOTE: Databases are NOT created here - they are created via Flyway migrations.

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

# Generate one random password per user
resource "random_password" "db_password" {
  for_each = var.users

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

# Create one SQL user per entry in var.users
resource "google_sql_user" "users" {
  for_each = var.users

  name     = each.key
  instance = google_sql_database_instance.main.name
  password = random_password.db_password[each.key].result
  project  = var.project_id
}

# Canonical per-user password secret (Terraform owns both CloudSQL user password AND secret value)
resource "google_secret_manager_secret" "db_password" {
  for_each = var.users

  project   = var.project_id
  secret_id = "beytra-db-password-${var.environment}-${each.key}"
  labels    = merge(var.labels, { system = "cloudsql", db_user = each.key })

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "db_password" {
  for_each = var.users

  secret      = google_secret_manager_secret.db_password[each.key].id
  secret_data = random_password.db_password[each.key].result
}

# Optional: grant shared accessor SAs to all per-user secrets
resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = {
    for pair in setproduct(keys(var.users), var.secret_accessor_service_accounts) :
    "${pair[0]}::${pair[1]}" => { user = pair[0], sa = pair[1] }
  }

  project   = var.project_id
  secret_id = google_secret_manager_secret.db_password[each.value.user].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.sa}"
}

# NOTE: Databases are NOT created here!
# They are created via Flyway migrations in beytra-db repository.
