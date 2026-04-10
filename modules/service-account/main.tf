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

locals {
  # Standard permission presets
  presets = {
    terraform = [
      # Cloud Run
      "run.services.create", "run.services.update", "run.services.delete",
      "run.services.get", "run.services.list",
      "run.services.getIamPolicy", "run.services.setIamPolicy",
      "run.revisions.get", "run.revisions.list",
      "run.operations.get",
      "run.jobs.get", "run.jobs.create", "run.jobs.update",
      # Secret Manager (shell only, also read versions for drift detection)
      "secretmanager.secrets.create", "secretmanager.secrets.get",
      "secretmanager.secrets.update", "secretmanager.secrets.list",
      "secretmanager.secrets.getIamPolicy", "secretmanager.secrets.setIamPolicy",
      "secretmanager.versions.get", "secretmanager.versions.list", "secretmanager.versions.access",
      # IAM
      "iam.roles.create", "iam.roles.update", "iam.roles.get", "iam.roles.list",
      "iam.serviceAccounts.create", "iam.serviceAccounts.get",
      "iam.serviceAccounts.getIamPolicy", "iam.serviceAccounts.setIamPolicy",
      "resourcemanager.projects.getIamPolicy", "resourcemanager.projects.setIamPolicy",
      # Workload Identity (for WIF-enabled SAs)
      "iam.workloadIdentityPools.get", "iam.workloadIdentityPools.list",
      "iam.workloadIdentityPoolProviders.get", "iam.workloadIdentityPoolProviders.list",
      # GCS (state bucket + bucket IAM + bucket lifecycle management)
      "storage.objects.get", "storage.objects.create", "storage.objects.delete", "storage.objects.list",
      "storage.buckets.get", "storage.buckets.create", "storage.buckets.update", "storage.buckets.delete", "storage.buckets.list",
      "storage.buckets.getIamPolicy", "storage.buckets.setIamPolicy",
      # Pub/Sub (for projects that use it)
      "pubsub.topics.get", "pubsub.topics.create", "pubsub.topics.update",
      "pubsub.subscriptions.get", "pubsub.subscriptions.create", "pubsub.subscriptions.update",
      # Artifact Registry (repos + IAM bindings)
      "artifactregistry.repositories.get", "artifactregistry.repositories.list",
      "artifactregistry.repositories.create", "artifactregistry.repositories.update", "artifactregistry.repositories.delete",
      "artifactregistry.repositories.getIamPolicy", "artifactregistry.repositories.setIamPolicy",
      "artifactregistry.repositories.downloadArtifacts",
      # DNS (for platform)
      "dns.managedZones.get", "dns.managedZones.list",
      "dns.resourceRecordSets.get", "dns.resourceRecordSets.list",
      # Compute (for platform: VPC, bastion, load balancer, NAT, etc.)
      "compute.networks.get", "compute.networks.list",
      "compute.subnetworks.get", "compute.subnetworks.list",
      "compute.addresses.get", "compute.addresses.list",
      "compute.routers.get", "compute.routers.list",
      "compute.instances.get", "compute.instances.list",
      "compute.firewalls.get", "compute.firewalls.list",
      "compute.urlMaps.get", "compute.urlMaps.list",
      "compute.targetHttpProxies.get", "compute.targetHttpProxies.list",
      "compute.targetHttpsProxies.get", "compute.targetHttpsProxies.list",
      "compute.globalForwardingRules.get", "compute.globalForwardingRules.list",
      "compute.globalAddresses.get", "compute.globalAddresses.list",
      "compute.sslCertificates.get", "compute.sslCertificates.list",
      "compute.backendServices.get", "compute.backendServices.list",
      "compute.backendBuckets.get", "compute.backendBuckets.list",
      "compute.securityPolicies.get", "compute.securityPolicies.list",
      "compute.regionNetworkEndpointGroups.get", "compute.regionNetworkEndpointGroups.list",
      # VPC Access Connector
      "vpcaccess.connectors.get", "vpcaccess.connectors.list",
      # Service Networking (VPC peering for Google services)
      "servicenetworking.services.get",
      "resourcemanager.projects.get",
      # Cloud SQL
      "cloudsql.instances.get", "cloudsql.instances.list",
      "cloudsql.users.get", "cloudsql.users.list",
      # Memorystore Redis
      "redis.instances.get", "redis.instances.list",
    ]
    deployer = [
      "run.services.get", "run.services.update",
      "run.revisions.get", "run.revisions.list", "run.operations.get",
      "run.jobs.get", "run.jobs.run", "run.executions.get", "run.executions.list",
      "artifactregistry.repositories.uploadArtifacts", "artifactregistry.repositories.downloadArtifacts",
      "artifactregistry.tags.create", "artifactregistry.tags.update",
      "iam.serviceAccounts.actAs",
    ]
  }

  # Merge preset with any additional custom permissions
  resolved_permissions = distinct(concat(
    var.preset != null ? local.presets[var.preset] : [],
    var.custom_role_permissions
  ))
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
  count = length(local.resolved_permissions) > 0 ? 1 : 0

  project     = var.project_id
  role_id     = replace(var.account_id, "-", "_")
  title       = "${var.display_name} Role"
  description = "Custom least-privilege role for ${var.display_name}"
  permissions = local.resolved_permissions
}

# Bind custom role to service account
resource "google_project_iam_member" "custom_role_binding" {
  count = length(local.resolved_permissions) > 0 ? 1 : 0

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
