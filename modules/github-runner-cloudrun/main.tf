# GitHub Actions Self-Hosted Runner Module (Cloud Run Jobs)
# Ephemeral runners that auto-scale on-demand and clean up automatically

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Service Account for Cloud Function (executes Cloud Run Jobs)
resource "google_service_account" "function_sa" {
  project      = var.project_id
  account_id   = "${var.gh_runner_name_prefix}-func-sa"
  display_name = "GitHub Runner Function SA"
  description  = "Service account for Cloud Function that executes GitHub runner jobs"
}

# IAM: Allow function to execute Cloud Run Jobs
resource "google_project_iam_member" "function_run_developer" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.function_sa.email}"
}

# IAM: Allow function to access GitHub App token secret
resource "google_secret_manager_secret_iam_member" "function_gh_runner_token" {
  secret_id = var.gh_runner_token_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.function_sa.email}"
}

# Cloud Run Job for GitHub Runner
resource "google_cloud_run_v2_job" "github_runner" {
  name     = "${var.gh_runner_name_prefix}-job"
  location = var.region
  project  = var.project_id

  template {
    template {
      service_account = var.gh_runner_service_account_email
      max_retries     = 0       # Don't retry failed jobs
      timeout         = "3600s" # 1 hour max

      # VPC Access for Cloud SQL private IP (10.109.0.3)
      vpc_access {
        connector = var.vpc_connector_id
        egress    = "PRIVATE_RANGES_ONLY"
      }

      containers {
        image = var.gh_runner_image

        resources {
          limits = {
            cpu    = var.cpu_limit
            memory = var.memory_limit
          }
        }

        env {
          name  = "GITHUB_ORG"
          value = var.github_org
        }

        env {
          name  = "GITHUB_REPO"
          value = var.github_repos[0] # TODO: Handle multiple repos with dynamic job creation
        }

        env {
          name  = "RUNNER_LABELS"
          value = join(",", var.gh_runner_labels)
        }

        env {
          name  = "PROJECT_ID"
          value = var.project_id
        }

        env {
          name  = "TOKEN_SECRET"
          value = var.gh_runner_token_secret_name
        }

        env {
          name  = "GITHUB_APP_ID"
          value = var.github_app_id
        }

        env {
          name  = "GITHUB_INSTALLATION_ID"
          value = var.github_installation_id
        }
      }
    }
  }

  labels = merge(var.labels, {
    component = "github-runner"
  })
}

# NOTE: Cloud Run Job no longer needs Secret Manager access
# Secret is fetched by Cloud Function and passed as environment variable
# Removed: google_secret_manager_secret_iam_member.job_runner_token

# IAM: Allow function SA to invoke the job
resource "google_cloud_run_v2_job_iam_member" "invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_job.github_runner.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.function_sa.email}"
}

# Get project number for Cloud Build service account
data "google_project" "project" {
  project_id = var.project_id
}

# Cloud Function: Webhook Receiver & Job Executor
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
resource "google_cloudfunctions2_function" "gh_runner_job_executor" {
  project     = var.project_id
  name        = "${var.gh_runner_name_prefix}-job-executor"
  location    = var.region
  description = "OIDC-authenticated endpoint that executes GitHub runner jobs"

  build_config {
    runtime     = "python311"
    entry_point = "execute_gh_runner_job"
    source {
      storage_source {
        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count             = 10
    min_instance_count             = 0
    available_memory               = "512M"
    timeout_seconds                = 60
    service_account_email          = google_service_account.function_sa.email
    all_traffic_on_latest_revision = true
    ingress_settings               = "ALLOW_ALL" # Allow external authenticated requests (IAM still required)

    environment_variables = {
      PROJECT_ID             = var.project_id
      REGION                 = var.region
      JOB_NAME               = google_cloud_run_v2_job.github_runner.name
      RUNNER_NAME_PREFIX     = var.gh_runner_name_prefix
      GITHUB_APP_SECRET_NAME = var.gh_runner_token_secret_name
    }
  }

  labels = var.labels
}

# ============================================================================
# OIDC / Workload Identity Federation for GitHub Actions
# ============================================================================

# Service Account that GitHub Actions will impersonate
resource "google_service_account" "github_actions_invoker" {
  project      = var.project_id
  account_id   = "${var.gh_runner_name_prefix}-gh-sa"
  display_name = "GitHub Actions OIDC Invoker SA"
  description  = "Service account impersonated by GitHub Actions via OIDC to invoke Cloud Run Jobs"
}

# Workload Identity Pool for external identities (GitHub)
resource "google_iam_workload_identity_pool" "github_pool" {
  project                   = var.project_id
  workload_identity_pool_id = "${var.gh_runner_name_prefix}-pool"
  display_name              = "GitHub Actions OIDC Pool"
  description               = "Identity pool for GitHub Actions OIDC authentication"
}

# OIDC Provider that trusts GitHub's token issuer
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.gh_runner_name_prefix}-provider"
  display_name                       = "GitHub OIDC Provider"
  description                        = "OIDC provider for GitHub Actions tokens"

  # GitHub's official OIDC issuer
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  # Map GitHub token claims to GCP attributes
  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.actor"            = "assertion.actor"
  }

  # Security: Only allow tokens from hof-media organization
  attribute_condition = "attribute.repository.startsWith('hof-media/')"
}

# Bind GitHub to the Service Account via Workload Identity
# This allows any repo in hof-media org to impersonate the SA
resource "google_service_account_iam_member" "github_workload_identity_user" {
  service_account_id = google_service_account.github_actions_invoker.name
  role               = "roles/iam.workloadIdentityUser"

  # Grant access to all repos in the hof-media GitHub organization
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository_owner/hof-media"
}

# Grant the GitHub workload identity pool permission to get OpenID tokens
# This is needed for the auth action to generate ID tokens
resource "google_service_account_iam_member" "github_openid_token_creator" {
  service_account_id = google_service_account.github_actions_invoker.name
  role               = "roles/iam.serviceAccountOpenIdTokenCreator"

  # Grant access to all repos in the hof-media GitHub organization
  member = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository_owner/hof-media"
}

# Grant the GitHub SA permission to invoke the private Cloud Function
resource "google_cloud_run_service_iam_member" "github_invoker" {
  project  = var.project_id
  location = var.region
  service  = google_cloudfunctions2_function.gh_runner_job_executor.service_config[0].service
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.github_actions_invoker.email}"
}

# Grant the GitHub SA permission to create identity tokens for itself
# This is needed for gcloud auth print-identity-token
resource "google_service_account_iam_member" "github_token_creator" {
  service_account_id = google_service_account.github_actions_invoker.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.github_actions_invoker.email}"
}
