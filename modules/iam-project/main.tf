# Project IAM and Service Account Management Module for Beytra ETL

# Service account for ETL pipeline
resource "google_service_account" "etl_service_account" {
  project      = var.project_id
  account_id   = "${var.project_name}-etl-sa"
  display_name = "${var.project_name} ETL Service Account"
  description  = "Service account for Beytra ETL pipeline operations"
}

# Service account key (optional, for local/CI/CD)
resource "google_service_account_key" "etl_key" {
  count              = var.create_service_account_key ? 1 : 0
  service_account_id = google_service_account.etl_service_account.name
}

# IAM roles for ETL service account
resource "google_project_iam_member" "etl_roles" {
  for_each = toset(var.etl_service_account_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.etl_service_account.email}"
}

# Grant workflow permission to execute Cloud Run Jobs
resource "google_project_iam_member" "workflow_job_invoker" {
  project = var.project_id
  role    = "roles/run.developer"
  member  = "serviceAccount:${google_service_account.etl_service_account.email}"
}

# Grant workflow logging permissions
resource "google_project_iam_member" "workflow_logger" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.etl_service_account.email}"
}

# Grant workflow execution permissions
resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.etl_service_account.email}"
}

# Grant eventarc event receiver permissions
resource "google_project_iam_member" "eventarc_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.etl_service_account.email}"
}

# Service account for GitHub Actions deployments
resource "google_service_account" "github_deploy" {
  count = var.create_github_deploy_sa ? 1 : 0

  project      = var.project_id
  account_id   = "${var.project_name}-github-deploy"
  display_name = "${var.project_name} GitHub Deploy Service Account"
  description  = "Service account for GitHub Actions to deploy Docker images and infrastructure"
}

# Service account key for GitHub Actions
resource "google_service_account_key" "github_deploy_key" {
  count              = var.create_github_deploy_sa && var.create_github_deploy_key ? 1 : 0
  service_account_id = google_service_account.github_deploy[0].name
}

# IAM roles for GitHub deploy service account
resource "google_project_iam_member" "github_deploy_roles" {
  for_each = var.create_github_deploy_sa ? toset(var.github_deploy_roles) : []

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_deploy[0].email}"
}

# Allow GitHub deploy SA to act as ETL service account for Cloud Run deployments
resource "google_service_account_iam_member" "github_deploy_act_as_etl" {
  count = var.create_github_deploy_sa ? 1 : 0

  service_account_id = google_service_account.etl_service_account.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.github_deploy[0].email}"
}

# Enable required APIs
resource "google_project_service" "required_apis" {
  for_each = toset(var.required_apis)

  project = var.project_id
  service = each.value

  disable_dependent_services = false
  disable_on_destroy         = false
}

# Grant GCS service agent permission to publish to Pub/Sub (needed for Eventarc)
resource "google_project_iam_member" "gcs_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gs-project-accounts.iam.gserviceaccount.com"

  depends_on = [google_project_service.required_apis]
}

# Grant workflow service account permission to publish to Pub/Sub
resource "google_project_iam_member" "workflow_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:${google_service_account.etl_service_account.email}"

  depends_on = [google_project_service.required_apis]
}
