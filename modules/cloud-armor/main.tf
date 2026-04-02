# Cloud Armor Security Policy
# Creates a security policy with deny-all default rule
# Whitelist rules for developer IPs and host-restricted rules for Cloud NAT

resource "google_compute_security_policy" "main" {
  name        = var.policy_name
  description = var.description
  project     = var.project_id

  # Full access whitelist (developers, CI/CD, etc.)
  dynamic "rule" {
    for_each = var.whitelisted_ips
    content {
      action   = "allow"
      priority = 1000 + rule.key
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = [rule.value]
        }
      }
      description = "Full access whitelist: ${rule.value}"
    }
  }

  # Cloud NAT IPs - restricted to auth.beytra.dev only
  # Allows internal services (Canvas, etc.) to access OIDC endpoints
  dynamic "rule" {
    for_each = length(var.cloud_nat_ips) > 0 && var.domain != "" ? var.cloud_nat_ips : []
    content {
      action   = "allow"
      priority = 2000 + rule.key
      match {
        expr {
          expression = "inIpRange(origin.ip, '${rule.value}/32') && has(request.headers['host']) && request.headers['host'] == 'auth.${var.domain}'"
        }
      }
      description = "Cloud NAT access to auth.${var.domain} only: ${rule.value}"
    }
  }

  # Cloud NAT IPs - restricted to api.beytra.dev (if service-to-service needed)
  dynamic "rule" {
    for_each = length(var.cloud_nat_ips) > 0 && var.domain != "" ? var.cloud_nat_ips : []
    content {
      action   = "allow"
      priority = 3000 + rule.key
      match {
        expr {
          expression = "inIpRange(origin.ip, '${rule.value}/32') && has(request.headers['host']) && request.headers['host'] == 'api.${var.domain}'"
        }
      }
      description = "Cloud NAT access to api.${var.domain} only: ${rule.value}"
    }
  }

  # Cloud NAT IPs - restricted to canvas.beytra.dev (OAuth token exchange)
  dynamic "rule" {
    for_each = length(var.cloud_nat_ips) > 0 && var.domain != "" ? var.cloud_nat_ips : []
    content {
      action   = "allow"
      priority = 4000 + rule.key
      match {
        expr {
          expression = "inIpRange(origin.ip, '${rule.value}/32') && has(request.headers['host']) && request.headers['host'] == 'canvas.${var.domain}'"
        }
      }
      description = "Cloud NAT access to canvas.${var.domain} only: ${rule.value}"
    }
  }

  # Default rule: Deny all traffic
  rule {
    action   = "deny(403)"
    priority = 2147483647 # Lowest priority = default action
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default deny rule"
  }

  # Adaptive protection for DDoS mitigation (optional)
  dynamic "adaptive_protection_config" {
    for_each = var.enable_adaptive_protection ? [1] : []
    content {
      layer_7_ddos_defense_config {
        enable          = true
        rule_visibility = "STANDARD"
      }
    }
  }
}
