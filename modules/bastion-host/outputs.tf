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

output "dbeaver_connection_instructions" {
  description = "Instructions for connecting DBeaver"
  value       = <<-EOT

  ✅ Bastion Host Deployed Successfully!

  Step 1: Create SSH tunnel (run in terminal):
    gcloud compute ssh ${google_compute_instance.bastion.name} --zone=${var.zone} --project=${var.project_id} --tunnel-through-iap -- -L 5434:localhost:5432 -N

  Step 2: Connect DBeaver:
    Host: localhost
    Port: 5434
    Database: postgres
    Username: beytra_user
    Password: (get from Secret Manager)

  To get password:
    gcloud secrets versions access latest --secret=beytra-db-dev --project=${var.project_id} | jq -r .DB_PASSWORD

  Keep the SSH tunnel running while using DBeaver.
  EOT
}
