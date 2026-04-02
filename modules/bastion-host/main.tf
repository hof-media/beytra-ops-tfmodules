# Bastion Host Module
# Small VM in VPC for accessing CloudSQL via SSH tunnel

# Service account for bastion host
resource "google_service_account" "bastion" {
  project      = var.project_id
  account_id   = "${var.bastion_name}-sa"
  display_name = "Bastion Host Service Account"
}

# Grant Cloud SQL Client role
resource "google_project_iam_member" "bastion_cloudsql" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.bastion.email}"
}

# Bastion host VM
resource "google_compute_instance" "bastion" {
  project      = var.project_id
  name         = var.bastion_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
      size  = 10
    }
  }

  network_interface {
    network = var.network_id
    # When using auto-created subnets, don't specify subnetwork - it uses default for the zone's region
    # No access_config = no external IP (use IAP for SSH)
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "FALSE"
  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -ex

# Install Cloud SQL Proxy
curl -o /usr/local/bin/cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64
chmod +x /usr/local/bin/cloud-sql-proxy

# Create systemd service for Cloud SQL Proxy
cat > /etc/systemd/system/cloud-sql-proxy.service <<'SYSTEMD'
[Unit]
Description=Cloud SQL Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/cloud-sql-proxy --address 0.0.0.0 --port 5432 --private-ip ${var.cloudsql_instance_connection_name}
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Enable and start the service
systemctl daemon-reload
systemctl enable cloud-sql-proxy
systemctl start cloud-sql-proxy

# Install Python and dependencies for Cloud Run auth proxy
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y python3 python3-requests

# Create Python auth proxy script
cat > /usr/local/bin/cloudrun-auth-proxy.py <<'PYTHON'
#!/usr/bin/env python3
"""
Cloud Run Authentication Proxy
Proxies requests to Cloud Run services with automatic authentication using service account identity tokens.
"""

import os
import sys
import requests
import logging
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse

logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s'
)

class CloudRunProxyHandler(BaseHTTPRequestHandler):
    def get_identity_token(self):
        """Fetch identity token from metadata service."""
        target_url = os.environ.get('TARGET_URL')
        if not target_url:
            raise ValueError("TARGET_URL environment variable not set")

        metadata_url = f"http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity?audience={target_url}"

        try:
            response = requests.get(
                metadata_url,
                headers={'Metadata-Flavor': 'Google'},
                timeout=5
            )
            response.raise_for_status()
            return response.text
        except Exception as e:
            logging.error(f"Failed to fetch identity token: {e}")
            raise

    def proxy_request(self, method):
        """Proxy the request to Cloud Run with authentication."""
        target_url = os.environ.get('TARGET_URL')
        if not target_url:
            self.send_error(500, "TARGET_URL not configured")
            return

        try:
            # Get identity token
            token = self.get_identity_token()

            # Build target URL with path and query
            full_url = target_url + self.path

            # Copy headers from incoming request
            headers = {}
            for header, value in self.headers.items():
                # Skip hop-by-hop headers
                if header.lower() not in ['host', 'connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade']:
                    headers[header] = value

            # Add authentication and set correct Host header
            headers['Authorization'] = f'Bearer {token}'
            parsed = urlparse(target_url)
            headers['Host'] = parsed.netloc

            # Read request body if present
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else None

            # Make the proxied request
            logging.info(f"{method} {self.path} -> {full_url}")
            response = requests.request(
                method=method,
                url=full_url,
                headers=headers,
                data=body,
                timeout=30,
                allow_redirects=False
            )

            # Send response back to client
            self.send_response(response.status_code)
            for header, value in response.headers.items():
                # Skip hop-by-hop headers
                if header.lower() not in ['connection', 'keep-alive', 'proxy-authenticate', 'proxy-authorization', 'te', 'trailers', 'transfer-encoding', 'upgrade']:
                    self.send_header(header, value)
            self.end_headers()
            self.wfile.write(response.content)

        except Exception as e:
            logging.error(f"Proxy error: {e}")
            self.send_error(502, f"Proxy error: {str(e)}")

    def do_GET(self):
        self.proxy_request('GET')

    def do_POST(self):
        self.proxy_request('POST')

    def do_PUT(self):
        self.proxy_request('PUT')

    def do_DELETE(self):
        self.proxy_request('DELETE')

    def do_PATCH(self):
        self.proxy_request('PATCH')

    def do_HEAD(self):
        self.proxy_request('HEAD')

    def do_OPTIONS(self):
        self.proxy_request('OPTIONS')

    def log_message(self, format, *args):
        """Override to use our logging configuration."""
        logging.info(format % args)


def main():
    port = int(os.environ.get('PORT', 8080))
    target_url = os.environ.get('TARGET_URL')

    if not target_url:
        logging.error("TARGET_URL environment variable must be set")
        sys.exit(1)

    server_address = ('0.0.0.0', port)
    httpd = HTTPServer(server_address, CloudRunProxyHandler)

    logging.info(f"Starting Cloud Run auth proxy on port {port}")
    logging.info(f"Target: {target_url}")

    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        logging.info("Shutting down...")
        httpd.shutdown()


if __name__ == '__main__':
    main()
PYTHON

chmod +x /usr/local/bin/cloudrun-auth-proxy.py

# Create systemd service for courses API proxy (port 8081)
cat > /etc/systemd/system/cloudrun-proxy-courses.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Courses API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8081"
Environment="TARGET_URL=${var.courses_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for topics API proxy (port 8082)
cat > /etc/systemd/system/cloudrun-proxy-topics.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Topics API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8082"
Environment="TARGET_URL=${var.topics_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for assignments API proxy (port 8083)
cat > /etc/systemd/system/cloudrun-proxy-assignments.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Assignments API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8083"
Environment="TARGET_URL=${var.assignments_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for concepts API proxy (port 8084)
cat > /etc/systemd/system/cloudrun-proxy-concepts.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Concepts API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8084"
Environment="TARGET_URL=${var.concepts_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for questions API proxy (port 8085)
cat > /etc/systemd/system/cloudrun-proxy-questions.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Questions API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8085"
Environment="TARGET_URL=${var.questions_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for students API proxy (port 8086)
cat > /etc/systemd/system/cloudrun-proxy-students.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Students API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8086"
Environment="TARGET_URL=${var.students_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for maps API proxy (port 8087)
cat > /etc/systemd/system/cloudrun-proxy-maps.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Maps API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8087"
Environment="TARGET_URL=${var.maps_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for documents API proxy (port 8101)
cat > /etc/systemd/system/cloudrun-proxy-documents.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Documents API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8101"
Environment="TARGET_URL=${var.documents_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for pages API proxy (port 8102)
cat > /etc/systemd/system/cloudrun-proxy-pages.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Pages API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8102"
Environment="TARGET_URL=${var.pages_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for media API proxy (port 8103)
cat > /etc/systemd/system/cloudrun-proxy-media.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Media API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8103"
Environment="TARGET_URL=${var.media_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for users API proxy (port 8104)
cat > /etc/systemd/system/cloudrun-proxy-users.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Users API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8104"
Environment="TARGET_URL=${var.users_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for roles API proxy (port 8105)
cat > /etc/systemd/system/cloudrun-proxy-roles.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Roles API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8105"
Environment="TARGET_URL=${var.roles_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for permissions API proxy (port 8106)
cat > /etc/systemd/system/cloudrun-proxy-permissions.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Permissions API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8106"
Environment="TARGET_URL=${var.permissions_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for universities API proxy (port 8107)
cat > /etc/systemd/system/cloudrun-proxy-universities.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Universities API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8107"
Environment="TARGET_URL=${var.universities_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Create systemd service for integrations API proxy (port 8108)
cat > /etc/systemd/system/cloudrun-proxy-integrations.service <<'SYSTEMD'
[Unit]
Description=Cloud Run Auth Proxy - Integrations API
After=network.target

[Service]
Type=simple
User=root
Environment="PORT=8108"
Environment="TARGET_URL=${var.integrations_api_url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SYSTEMD

# Enable and start Cloud Run auth proxy services
systemctl daemon-reload
systemctl enable cloudrun-proxy-courses cloudrun-proxy-topics cloudrun-proxy-assignments cloudrun-proxy-concepts cloudrun-proxy-questions cloudrun-proxy-students cloudrun-proxy-maps cloudrun-proxy-documents cloudrun-proxy-pages cloudrun-proxy-media cloudrun-proxy-users cloudrun-proxy-roles cloudrun-proxy-permissions cloudrun-proxy-universities cloudrun-proxy-integrations
systemctl start cloudrun-proxy-courses cloudrun-proxy-topics cloudrun-proxy-assignments cloudrun-proxy-concepts cloudrun-proxy-questions cloudrun-proxy-students cloudrun-proxy-maps cloudrun-proxy-documents cloudrun-proxy-pages cloudrun-proxy-media cloudrun-proxy-users cloudrun-proxy-roles cloudrun-proxy-permissions cloudrun-proxy-universities cloudrun-proxy-integrations
EOF

  labels = var.labels

  tags = ["bastion", "ssh"]
}

# Firewall rule to allow SSH from IAP
resource "google_compute_firewall" "bastion_iap" {
  project = var.project_id
  name    = "${var.bastion_name}-allow-iap"
  network = var.network_id

  allow {
    protocol = "tcp"
    ports    = ["22", "5432", "8081", "8082", "8083", "8084", "8085", "8086", "8087", "8101", "8102", "8103", "8104", "8105", "8106", "8107", "8108"] # SSH, Cloud SQL Proxy, and Cloud Run API proxies
  }

  # IAP's IP range for TCP forwarding
  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["bastion"]
}

# Note: IAP tunneling permissions are granted at project level via bastion-access-iam modules
# Instance-level IAM bindings are not supported for IAP roles
