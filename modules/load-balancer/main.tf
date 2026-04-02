# Global HTTP(S) Load Balancer with host-based routing
# Supports Cloud Run backends and GCS bucket backends

# Static external IP address
resource "google_compute_global_address" "main" {
  name         = "${var.name}-ip"
  project      = var.project_id
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
}

# Google-managed SSL certificates (one per domain for independent provisioning)
resource "google_compute_managed_ssl_certificate" "domain" {
  for_each = toset(var.ssl_domains)

  name    = "${var.name}-cert-${replace(each.value, ".", "-")}"
  project = var.project_id

  managed {
    domains = [each.value]
  }
}

# Backend buckets for GCS static sites
resource "google_compute_backend_bucket" "gcs" {
  for_each = var.gcs_backends

  name        = "${var.name}-${each.key}-bucket"
  project     = var.project_id
  bucket_name = each.value.bucket_name
  enable_cdn  = each.value.enable_cdn

  # Custom response headers (optional)
  custom_response_headers = each.value.custom_headers
}

# Serverless NEGs for Cloud Run services
resource "google_compute_region_network_endpoint_group" "cloudrun" {
  for_each = var.cloudrun_backends

  name                  = "${var.name}-${each.key}-neg"
  project               = var.project_id
  region                = each.value.region
  network_endpoint_type = "SERVERLESS"

  cloud_run {
    service = each.value.service_name
  }
}

# Backend services for Cloud Run (wraps the NEG)
resource "google_compute_backend_service" "cloudrun" {
  for_each = var.cloudrun_backends

  name     = "${var.name}-${each.key}-backend"
  project  = var.project_id
  protocol = "HTTPS"
  # Note: timeout_sec is not supported for Serverless NEGs (Cloud Run backends)
  # Timeouts are handled by the Cloud Run service itself and the client

  backend {
    group = google_compute_region_network_endpoint_group.cloudrun[each.key].id
  }

  # Attach Cloud Armor security policy
  security_policy = var.security_policy_self_link

  log_config {
    enable      = true
    sample_rate = 1.0
  }
}

# URL Map with host-based routing
resource "google_compute_url_map" "main" {
  name            = "${var.name}-urlmap"
  project         = var.project_id
  default_service = var.default_backend_type == "cloudrun" ? google_compute_backend_service.cloudrun[var.default_backend_key].id : google_compute_backend_bucket.gcs[var.default_backend_key].id

  # Host rules for each subdomain
  dynamic "host_rule" {
    for_each = var.host_rules
    content {
      hosts        = host_rule.value.hosts
      path_matcher = host_rule.key
    }
  }

  # Path matchers (one per host rule)
  dynamic "path_matcher" {
    for_each = var.host_rules
    content {
      name = path_matcher.key
      default_service = (
        path_matcher.value.backend_type == "cloudrun"
        ? google_compute_backend_service.cloudrun[path_matcher.value.backend_key].id
        : google_compute_backend_bucket.gcs[path_matcher.value.backend_key].id
      )

      # Root path redirect (e.g., "/" -> "/storybook/latest/index.html")
      dynamic "path_rule" {
        for_each = path_matcher.value.root_redirect_path != null ? [1] : []
        content {
          paths = ["/"]
          url_redirect {
            path_redirect          = path_matcher.value.root_redirect_path
            redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
            strip_query            = false
          }
        }
      }

      # Optional path rules for more specific routing
      dynamic "path_rule" {
        for_each = path_matcher.value.path_rules != null ? path_matcher.value.path_rules : []
        content {
          paths = path_rule.value.paths
          service = (
            path_rule.value.backend_type == "cloudrun"
            ? google_compute_backend_service.cloudrun[path_rule.value.backend_key].id
            : google_compute_backend_bucket.gcs[path_rule.value.backend_key].id
          )
        }
      }
    }
  }
}

# Target HTTPS Proxy
resource "google_compute_target_https_proxy" "main" {
  name             = "${var.name}-https-proxy"
  project          = var.project_id
  url_map          = google_compute_url_map.main.id
  ssl_certificates = [for cert in google_compute_managed_ssl_certificate.domain : cert.id]
}

# HTTP to HTTPS redirect (optional)
resource "google_compute_url_map" "http_redirect" {
  count = var.enable_http_redirect ? 1 : 0

  name    = "${var.name}-http-redirect"
  project = var.project_id

  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

resource "google_compute_target_http_proxy" "redirect" {
  count = var.enable_http_redirect ? 1 : 0

  name    = "${var.name}-http-proxy"
  project = var.project_id
  url_map = google_compute_url_map.http_redirect[0].id
}

resource "google_compute_global_forwarding_rule" "http_redirect" {
  count = var.enable_http_redirect ? 1 : 0

  name                  = "${var.name}-http-rule"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.redirect[0].id
  ip_address            = google_compute_global_address.main.id
}

# Global Forwarding Rule (HTTPS)
resource "google_compute_global_forwarding_rule" "https" {
  name                  = "${var.name}-https-rule"
  project               = var.project_id
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.main.id
  ip_address            = google_compute_global_address.main.id
}
