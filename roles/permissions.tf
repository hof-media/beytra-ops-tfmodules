# Canonical permission sets for Beytra service accounts.
# Import these as a module or copy the locals into your project's .iac/main.tf.
#
# Usage:
#   module "roles" {
#     source = "github.com/hof-media/beytra-ops-tfmodules//roles?ref=v1.0.0"
#   }
#   # Then use: module.roles.cloud_run_runtime_permissions

locals {
  # Runtime permissions for a Cloud Run service that:
  # - Reads secrets from Secret Manager
  # - Connects to Cloud SQL via VPC
  # - Reads/writes GCS objects
  # - Invokes other Cloud Run services
  cloud_run_runtime_permissions = [
    "secretmanager.versions.access",
    "secretmanager.versions.list",
    "cloudsql.instances.connect",
    "cloudsql.instances.get",
    "storage.objects.get",
    "storage.objects.list",
    "storage.objects.create",
    "storage.objects.delete",
    "run.routes.invoke",
  ]

  # CI/CD permissions for deploying Cloud Run services
  cloud_run_deployer_permissions = [
    "run.services.get",
    "run.services.update",
    "run.services.getIamPolicy",
    "run.revisions.get",
    "run.revisions.list",
    "run.operations.get",
    "artifactregistry.repositories.uploadArtifacts",
    "artifactregistry.repositories.downloadArtifacts",
    "artifactregistry.tags.create",
    "artifactregistry.tags.update",
    "iam.serviceAccounts.actAs",
  ]

  # Permissions for GCS signed URL generation
  gcs_signer_permissions = [
    "storage.objects.get",
    "storage.objects.list",
    "iam.serviceAccounts.signBlob",
  ]

  # Permissions for Cloud Run Job execution (migrations, automation)
  cloud_run_job_executor_permissions = [
    "run.jobs.get",
    "run.jobs.run",
    "run.executions.get",
    "run.executions.list",
    "logging.logEntries.list",
  ]

  # Read-only permissions for secret access (used by runtime SAs)
  secret_reader_permissions = [
    "secretmanager.versions.access",
    "secretmanager.versions.list",
  ]
}

output "cloud_run_runtime_permissions" {
  value = local.cloud_run_runtime_permissions
}

output "cloud_run_deployer_permissions" {
  value = local.cloud_run_deployer_permissions
}

output "gcs_signer_permissions" {
  value = local.gcs_signer_permissions
}

output "cloud_run_job_executor_permissions" {
  value = local.cloud_run_job_executor_permissions
}

output "secret_reader_permissions" {
  value = local.secret_reader_permissions
}
