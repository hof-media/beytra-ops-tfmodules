# Classic VPN Module (Policy-Based - Works with macOS built-in VPN)
# Simpler and compatible with standard IKEv2 clients

# Reserve static IP for VPN gateway
resource "google_compute_address" "vpn_gateway_ip" {
  project = var.project_id
  name    = "${var.gateway_name}-ip"
  region  = var.region
}

# Classic VPN Gateway
resource "google_compute_vpn_gateway" "vpn_gateway" {
  project = var.project_id
  name    = var.gateway_name
  region  = var.region
  network = var.network_id
}

# Forwarding rules for ESP traffic
resource "google_compute_forwarding_rule" "fr_esp" {
  project     = var.project_id
  name        = "${var.gateway_name}-fr-esp"
  region      = var.region
  ip_protocol = "ESP"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

# Forwarding rules for UDP 500 (IKE)
resource "google_compute_forwarding_rule" "fr_udp500" {
  project     = var.project_id
  name        = "${var.gateway_name}-fr-udp500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "500"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

# Forwarding rules for UDP 4500 (NAT-T)
resource "google_compute_forwarding_rule" "fr_udp4500" {
  project     = var.project_id
  name        = "${var.gateway_name}-fr-udp4500"
  region      = var.region
  ip_protocol = "UDP"
  port_range  = "4500"
  ip_address  = google_compute_address.vpn_gateway_ip.address
  target      = google_compute_vpn_gateway.vpn_gateway.id
}

# VPN Tunnel
resource "google_compute_vpn_tunnel" "tunnel" {
  project                 = var.project_id
  name                    = "${var.gateway_name}-tunnel"
  region                  = var.region
  peer_ip                 = var.peer_external_gateway_ip
  shared_secret           = var.shared_secret
  target_vpn_gateway      = google_compute_vpn_gateway.vpn_gateway.id
  local_traffic_selector  = ["10.109.0.0/20"] # GCP VPC CIDR
  remote_traffic_selector = var.vpn_local_network_cidrs

  depends_on = [
    google_compute_forwarding_rule.fr_esp,
    google_compute_forwarding_rule.fr_udp500,
    google_compute_forwarding_rule.fr_udp4500,
  ]
}

# Route to direct VPN traffic
resource "google_compute_route" "vpn_route" {
  project             = var.project_id
  name                = "${var.gateway_name}-route"
  network             = var.network_id
  dest_range          = var.vpn_local_network_cidrs[0]
  priority            = 1000
  next_hop_vpn_tunnel = google_compute_vpn_tunnel.tunnel.id
}

# Firewall rule to allow VPN traffic
resource "google_compute_firewall" "allow_vpn" {
  project = var.project_id
  name    = "${var.gateway_name}-allow-vpn"
  network = var.network_id

  allow {
    protocol = "tcp"
  }

  allow {
    protocol = "udp"
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = var.vpn_local_network_cidrs
  description   = "Allow traffic from VPN-connected local network"
}
