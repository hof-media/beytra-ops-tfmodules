# GitHub Actions Self-Hosted Runner Module
# Auto-scaling runner that starts on-demand and shuts down after jobs

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Service Account for Cloud Function (starts/stops VMs)
resource "google_service_account" "function_sa" {
  project      = var.project_id
  account_id   = "${var.runner_name_prefix}-function-sa"
  display_name = "GitHub Runner Function SA"
  description  = "Service account for Cloud Function that manages GitHub runner VMs"
}

# IAM: Allow function to create/delete VMs
resource "google_project_iam_member" "function_compute_admin" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

# IAM: Allow function to access secrets
resource "google_secret_manager_secret_iam_member" "function_webhook_secret" {
  secret_id = var.webhook_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "function_runner_token" {
  secret_id = var.runner_token_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_sa.email}"
}

# IAM: Allow function to pass service account to VMs
resource "google_service_account_iam_member" "function_sa_user" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${var.runner_service_account_email}"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.function_sa.email}"
}

# Compute Engine Instance Template
resource "google_compute_instance_template" "runner" {
  name_prefix  = "${var.runner_name_prefix}-"
  project      = var.project_id
  machine_type = var.machine_type
  region       = var.region

  tags = ["github-runner", "allow-ssh"]

  disk {
    # Use custom image if provided, otherwise fallback to Ubuntu base
    source_image = var.runner_image != "" ? var.runner_image : "ubuntu-os-cloud/ubuntu-2204-lts"
    auto_delete  = true
    boot         = true
    disk_size_gb = var.disk_size_gb
    disk_type    = "pd-standard"
  }

  network_interface {
    network    = var.network_id
    subnetwork = var.subnet_id
    # No external IP - uses Cloud NAT for outbound
  }

  service_account {
    email  = var.runner_service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = templatefile("${path.module}/startup-script.sh", {
      github_org             = var.github_org
      github_repo            = var.github_repos[0] # TODO: Handle multiple repos
      runner_labels          = join(",", var.runner_labels)
      project_id             = var.project_id
      token_secret           = var.runner_token_secret_name
      github_app_id          = var.github_app_id
      github_installation_id = var.github_installation_id
    })
    shutdown-script = "sudo shutdown -h now"
  }

  labels = merge(var.labels, {
    component = "github-runner"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Get project number for Cloud Build service account
data "google_project" "project" {
  project_id = var.project_id
}

# Cloud Function: Webhook Receiver & VM Manager
resource "google_storage_bucket" "function_source" {
  project                     = var.project_id
  name                        = "${var.project_id}-github-runner-function"
  location                    = var.region
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = var.labels
}

# Upload Cloud Function source code
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/cloud-function"
  output_path = "${path.module}/cloud-function.zip"
}

resource "google_storage_bucket_object" "function_source" {
  name   = "cloud-function-${data.archive_file.function_source.output_md5}.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function_source.output_path
}

# Grant Cloud Build service account access to the storage bucket
resource "google_storage_bucket_iam_member" "cloudbuild_access" {
  bucket = google_storage_bucket.function_source.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"
}

# Cloud Function v2
resource "google_cloudfunctions2_function" "webhook_receiver" {
  project     = var.project_id
  name        = "${var.runner_name_prefix}-webhook"
  location    = var.region
  description = "Receives GitHub webhooks and starts runner VMs"

  build_config {
    runtime     = "python311"
    entry_point = "handle_webhook"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count    = 10
    min_instance_count    = 0
    available_memory      = "512M"
    timeout_seconds       = 60
    service_account_email = google_service_account.function_sa.email

    environment_variables = {
      PROJECT_ID          = var.project_id
      ZONE                = var.zone
      INSTANCE_TEMPLATE   = google_compute_instance_template.runner.name
      WEBHOOK_SECRET_NAME = var.webhook_secret_name
      RUNNER_TOKEN_SECRET = var.runner_token_secret_name
      RUNNER_NAME_PREFIX  = var.runner_name_prefix
    }
  }

  labels = var.labels
}

# Allow unauthenticated invocations (GitHub webhook)
resource "google_cloudfunctions2_function_iam_member" "invoker" {
  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.webhook_receiver.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
