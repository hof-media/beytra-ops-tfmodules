resource "google_cloud_run_v2_service" "etl_processor" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  template {
    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    containers {
      image   = var.container_image
      command = var.container_command
      args    = var.container_args

      resources {
        limits = {
          cpu    = var.cpu_limit
          memory = var.memory_limit
        }
        cpu_idle          = var.cpu_idle
        startup_cpu_boost = var.startup_cpu_boost
      }

      ports {
        container_port = var.container_port
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }

      # Environment variables sourced from Secret Manager
      dynamic "env" {
        for_each = var.secret_env_vars
        content {
          name = env.value.name
          value_source {
            secret_key_ref {
              secret  = env.value.secret_name
              version = env.value.version
            }
          }
        }
      }

      # Mount secret volumes as files
      dynamic "volume_mounts" {
        for_each = var.secret_volumes
        content {
          name       = volume_mounts.value.name
          mount_path = volume_mounts.value.mount_path
        }
      }

      # Startup probe for services that need longer init time (e.g., Zitadel DB init)
      # startup_probe_timeout = total seconds to allow for startup (e.g., 300 = 5 minutes)
      dynamic "startup_probe" {
        for_each = var.startup_probe_timeout != null ? [1] : []
        content {
          tcp_socket {
            port = var.container_port
          }
          initial_delay_seconds = 0
          period_seconds        = 10                                   # Check every 10 seconds
          timeout_seconds       = 5                                    # Each check times out after 5s (must be < period)
          failure_threshold     = ceil(var.startup_probe_timeout / 10) # Total startup time = period * threshold
        }
      }
    }

    max_instance_request_concurrency = var.max_concurrency
    service_account                  = var.service_account_email
    timeout                          = var.timeout

    # VPC Access configuration (optional)
    dynamic "vpc_access" {
      for_each = var.vpc_connector_id != null ? [1] : []
      content {
        connector = var.vpc_connector_id
        egress    = var.vpc_egress
      }
    }

    # Secret volumes from Secret Manager
    dynamic "volumes" {
      for_each = var.secret_volumes
      content {
        name = volumes.value.name
        secret {
          secret = volumes.value.secret_name
          items {
            version = "latest"
            path    = volumes.value.file_name
          }
        }
      }
    }
  }

  ingress = var.ingress

  labels = var.labels

  # Explicit traffic config — always route 100% to the latest ready revision.
  #
  # Without this block, the Google provider records whatever spec.traffic
  # Cloud Run emits on create (which pins to a specific revisionName, not
  # LATEST). Then gcloud run deploy creates new revisions that never receive
  # traffic because the pinned revisionName stays fixed. Existing services in
  # this state need a terraform apply with this block to flip them to
  # latestRevision=true.
  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

# Allow service account to invoke the Cloud Run service
resource "google_cloud_run_v2_service_iam_member" "invoker" {
  name     = google_cloud_run_v2_service.etl_processor.name
  location = google_cloud_run_v2_service.etl_processor.location
  project  = google_cloud_run_v2_service.etl_processor.project

  role   = "roles/run.invoker"
  member = "serviceAccount:${var.service_account_email}"
}

# Allow unauthenticated access if specified
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_unauthenticated ? 1 : 0

  name     = google_cloud_run_v2_service.etl_processor.name
  location = google_cloud_run_v2_service.etl_processor.location
  project  = google_cloud_run_v2_service.etl_processor.project

  role   = "roles/run.invoker"
  member = "allUsers"
}

# Allow domain-restricted access if specified
resource "google_cloud_run_v2_service_iam_member" "domain_invoker" {
  count = var.allowed_domain != null ? 1 : 0

  name     = google_cloud_run_v2_service.etl_processor.name
  location = google_cloud_run_v2_service.etl_processor.location
  project  = google_cloud_run_v2_service.etl_processor.project

  role   = "roles/run.invoker"
  member = "domain:${var.allowed_domain}"
}

# Additional invokers (bastion, gateway, hooks, etc.)
resource "google_cloud_run_v2_service_iam_member" "additional_invokers" {
  for_each = toset(var.additional_invokers)

  name     = google_cloud_run_v2_service.etl_processor.name
  location = google_cloud_run_v2_service.etl_processor.location
  project  = google_cloud_run_v2_service.etl_processor.project

  role   = "roles/run.invoker"
  member = each.value
}
