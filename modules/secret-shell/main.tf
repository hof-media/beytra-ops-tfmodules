# Secret Shell Module
# Creates a Secret Manager secret container and IAM bindings WITHOUT managing the secret value.
# Values must be populated externally via gcloud CLI or CI/CD pipeline.
#
# Usage:
#   module "db_secret" {
#     source = "github.com/hof-media/beytra-ops-tfmodules//modules/secret-shell?ref=v1.0.0"
#     project_id  = "beytra-dev"
#     secret_id   = "beytra-api-courses-dev"
#     labels      = { application = "beytra-api-courses", environment = "dev" }
#     required_fields = ["DB_USER", "DB_PASSWORD", "DB_HOST", "DB_PORT", "DB_NAME"]
#     accessor_service_accounts = ["sa@project.iam.gserviceaccount.com"]
#   }
#
# After apply, populate the secret:
#   gcloud secrets versions add beytra-api-courses-dev \
#     --data-file=- <<< '{"DB_USER":"...","DB_PASSWORD":"...","DB_HOST":"..."}'

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

resource "google_secret_manager_secret" "secret" {
  project   = var.project_id
  secret_id = var.secret_id

  replication {
    auto {}
  }

  labels = var.labels

  # Annotations document the expected secret shape for operators
  annotations = {
    required_fields = join(", ", var.required_fields)
    populate_cmd    = "gcloud secrets versions add ${var.secret_id} --project=${var.project_id} --data-file=secrets.json"
  }
}

# Grant read access to specified service accounts
resource "google_secret_manager_secret_iam_member" "accessor" {
  count = length(var.accessor_service_accounts)

  project   = var.project_id
  secret_id = google_secret_manager_secret.secret.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${var.accessor_service_accounts[count.index]}"
}
