# Service Account Module
# Creates a GCP service account with a custom least-privilege IAM role.
# Optionally configures Workload Identity Federation for keyless GitHub Actions auth.
#
# Usage:
#   module "runtime_sa" {
#     source = "github.com/hof-media/beytra-ops-tfmodules//modules/service-account?ref=v1.0.0"
#     project_id   = "beytra-dev"
#     account_id   = "beytra-api-courses"
#     display_name = "Beytra API Courses Runtime"
#     custom_role_permissions = [
#       "secretmanager.versions.access",
#       "cloudsql.instances.connect",
#       "storage.objects.get",
#     ]
#   }

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Service Account
resource "google_service_account" "sa" {
  project      = var.project_id
  account_id   = var.account_id
  display_name = var.display_name
  description  = var.description
}

# Custom IAM Role (least-privilege)
resource "google_project_iam_custom_role" "role" {
  count = length(var.custom_role_permissions) > 0 ? 1 : 0

  project     = var.project_id
  role_id     = replace(var.account_id, "-", "_")
  title       = "${var.display_name} Role"
  description = "Custom least-privilege role for ${var.display_name}"
  permissions = var.custom_role_permissions
}

# Bind custom role to service account
resource "google_project_iam_member" "custom_role_binding" {
  count = length(var.custom_role_permissions) > 0 ? 1 : 0

  project = var.project_id
  role    = google_project_iam_custom_role.role[0].id
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# Additional predefined role bindings (for roles that can't be replicated as custom)
resource "google_project_iam_member" "predefined_roles" {
  for_each = toset(var.predefined_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
}

# Service Account Key (opt-in, discouraged — prefer Workload Identity)
resource "google_service_account_key" "key" {
  count              = var.create_key ? 1 : 0
  service_account_id = google_service_account.sa.name
}

# Workload Identity: Allow GitHub Actions to impersonate this SA
resource "google_service_account_iam_member" "workload_identity" {
  count = var.github_repo != null ? 1 : 0

  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${var.workload_identity_pool}/attribute.repository/${var.github_repo}"
}

# Allow another SA to act as this SA (e.g., deploy SA acts as runtime SA)
resource "google_service_account_iam_member" "act_as" {
  for_each = toset(var.impersonators)

  service_account_id = google_service_account.sa.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${each.value}"
}
