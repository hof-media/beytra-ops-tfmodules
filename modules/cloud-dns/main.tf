# Cloud DNS Managed Zone and Records
# Creates a DNS zone for the domain and A records for subdomains

resource "google_dns_managed_zone" "main" {
  name        = var.zone_name
  dns_name    = "${var.domain}."
  description = "DNS zone for ${var.domain}"
  project     = var.project_id

  visibility = "public"

  dnssec_config {
    state = var.enable_dnssec ? "on" : "off"
  }

  labels = var.labels
}

# A records for subdomains pointing to the load balancer IP
resource "google_dns_record_set" "subdomain" {
  for_each = var.subdomains

  name         = "${each.key}.${var.domain}."
  type         = "A"
  ttl          = var.record_ttl
  managed_zone = google_dns_managed_zone.main.name
  project      = var.project_id

  rrdatas = [var.load_balancer_ip]
}

# Optional: Root domain A record
resource "google_dns_record_set" "root" {
  count = var.create_root_record ? 1 : 0

  name         = "${var.domain}."
  type         = "A"
  ttl          = var.record_ttl
  managed_zone = google_dns_managed_zone.main.name
  project      = var.project_id

  rrdatas = [var.load_balancer_ip]
}
