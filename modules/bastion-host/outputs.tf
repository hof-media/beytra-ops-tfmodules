output "bastion_name" {
  description = "Name of the bastion host"
  value       = google_compute_instance.bastion.name
}

output "bastion_private_ip" {
  description = "Private IP of bastion host"
  value       = google_compute_instance.bastion.network_interface[0].network_ip
}

output "ssh_command" {
  description = "SSH command to connect to bastion"
  value       = "gcloud compute ssh ${google_compute_instance.bastion.name} --zone=${var.zone} --project=${var.project_id} --tunnel-through-iap"
}

output "ssh_tunnel_command" {
  description = "SSH tunnel command for DBeaver"
  value       = "gcloud compute ssh ${google_compute_instance.bastion.name} --zone=${var.zone} --project=${var.project_id} --tunnel-through-iap -- -L 5434:localhost:5432 -N"
}

output "service_account_email" {
  description = "Email of the bastion service account (grant run.invoker on Cloud Run services to it)"
  value       = google_service_account.bastion.email
}

output "cloudrun_proxy_ports" {
  description = "Map of service name => bastion-side port (useful for dev docker-compose env config)"
  value       = { for k, v in var.cloudrun_services : k => v.port }
}
