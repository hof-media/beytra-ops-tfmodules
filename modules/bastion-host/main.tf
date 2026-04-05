# Bastion Host Module
# IAP-only SSH entrypoint + Cloud Run auth proxies for dev tunnels.
# Services are configured via a map — adding a new service requires only an
# entry in var.cloudrun_services and var.invoker_service_names.

# Service account for bastion host
resource "google_service_account" "bastion" {
  project      = var.project_id
  account_id   = "${var.bastion_name}-sa"
  display_name = "Bastion Host Service Account"
}

# Cloud SQL client access (proxy uses VM metadata token)
resource "google_project_iam_member" "bastion_cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

# Cloud Run invoker: one binding per service in invoker_service_names.
# Scoped to the service (not project-level) to limit blast radius.
resource "google_cloud_run_v2_service_iam_member" "bastion_invoker" {
  for_each = { for s in var.invoker_service_names : s.service_name => s }

  project  = var.project_id
  location = each.value.region
  name     = each.value.service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.bastion.email}"
}

# Firewall: IAP TCP forwarding only
resource "google_compute_firewall" "bastion_iap" {
  project = var.project_id
  name    = "${var.bastion_name}-allow-iap"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports = distinct(concat(
      ["22", "5432"],
      [for s in var.cloudrun_services : tostring(s.port)],
    ))
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["bastion"]
}

# Bastion VM
resource "google_compute_instance" "bastion" {
  project      = var.project_id
  name         = var.bastion_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  network_interface {
    network = var.network_id
    # no access_config = no external IP (IAP only)
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
  }

  metadata_startup_script = templatefile("${path.module}/files/startup.sh.tpl", {
    cloudsql_instance_connection_name = var.cloudsql_instance_connection_name
    cloudrun_services_json            = jsonencode(var.cloudrun_services)
    cloudrun_auth_proxy_py            = file("${path.module}/files/cloudrun-auth-proxy.py")
  })

  labels = var.labels
  tags   = ["bastion", "ssh"]
}
