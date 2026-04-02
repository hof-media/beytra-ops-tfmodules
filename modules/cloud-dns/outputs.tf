output "zone_name" {
  description = "Name of the DNS zone"
  value       = google_dns_managed_zone.main.name
}

output "dns_name" {
  description = "DNS name of the zone"
  value       = google_dns_managed_zone.main.dns_name
}

output "name_servers" {
  description = "Nameservers for the DNS zone (configure these in your domain registrar)"
  value       = google_dns_managed_zone.main.name_servers
}

output "subdomain_records" {
  description = "Map of subdomain names to their FQDNs"
  value = {
    for subdomain, _ in var.subdomains :
    subdomain => "${subdomain}.${var.domain}"
  }
}
