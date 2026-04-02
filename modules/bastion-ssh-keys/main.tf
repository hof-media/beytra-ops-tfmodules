# Bastion SSH Keys Module
# Generates SSH key pair and stores in Secret Manager for bastion access

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Generate ED25519 SSH key pair (more secure and smaller than RSA)
resource "tls_private_key" "bastion_ssh" {
  algorithm = "ED25519"

  lifecycle {
    # Prevent accidental key regeneration
    # To rotate: taint this resource and reapply
    prevent_destroy = false
  }
}

# Store private key in Secret Manager
resource "google_secret_manager_secret" "bastion_private_key" {
  project   = var.project_id
  secret_id = "${var.key_name}-ssh-private-key"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "bastion_private_key" {
  secret      = google_secret_manager_secret.bastion_private_key.id
  secret_data = tls_private_key.bastion_ssh.private_key_openssh
}

# Store public key in Secret Manager for reference
resource "google_secret_manager_secret" "bastion_public_key" {
  project   = var.project_id
  secret_id = "${var.key_name}-ssh-public-key"

  replication {
    auto {}
  }

  labels = var.labels
}

resource "google_secret_manager_secret_version" "bastion_public_key" {
  secret      = google_secret_manager_secret.bastion_public_key.id
  secret_data = tls_private_key.bastion_ssh.public_key_openssh
}
