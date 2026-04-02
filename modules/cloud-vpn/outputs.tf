output "vpn_gateway_ip" {
  description = "IP address of VPN gateway (use this in macOS VPN settings)"
  value       = google_compute_address.vpn_gateway_ip.address
}

output "vpn_gateway_id" {
  description = "ID of the VPN gateway"
  value       = google_compute_vpn_gateway.vpn_gateway.id
}

output "tunnel_name" {
  description = "Name of VPN tunnel"
  value       = google_compute_vpn_tunnel.tunnel.name
}

output "setup_instructions" {
  description = "Instructions for completing VPN setup on macOS"
  value       = <<-EOT

  ✅ VPN Gateway Created Successfully!

  Gateway IP: ${google_compute_address.vpn_gateway_ip.address}

  macOS Built-in VPN Setup (System Settings):

  1. Open System Settings → Network → Click +
  2. Interface: VPN, VPN Type: IKEv2
  3. Server Address: ${google_compute_address.vpn_gateway_ip.address}
  4. Remote ID: ${google_compute_address.vpn_gateway_ip.address}
  5. Local ID: Leave blank
  6. Authentication Settings → Shared Secret: ${var.shared_secret}
  7. Click Connect

  Test connectivity:
    ping 10.109.0.3  # CloudSQL private IP

  Then start Cloud SQL Proxy:
    cd /Users/jacobhoffman/hm/beytra-db
    docker-compose -f docker-compose.dev.yml up -d cloudsql-proxy

  Connect DBeaver to localhost:5434
  EOT
}
