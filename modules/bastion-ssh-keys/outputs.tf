# Bastion SSH Keys Module Outputs

output "ssh_public_key" {
  description = "SSH public key for bastion host metadata"
  value       = tls_private_key.bastion_ssh.public_key_openssh
}

output "private_key_secret_id" {
  description = "Secret Manager secret ID for SSH private key"
  value       = google_secret_manager_secret.bastion_private_key.secret_id
}

output "public_key_secret_id" {
  description = "Secret Manager secret ID for SSH public key"
  value       = google_secret_manager_secret.bastion_public_key.secret_id
}
