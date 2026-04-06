#!/bin/bash
# Bastion startup script (rendered by terraform templatefile()).
# Installs Cloud SQL Proxy + Python auth proxy, generates one systemd unit
# per entry in cloudrun_services_json. Reruns require VM replace (metadata startup).
set -euxo pipefail

# --- Cloud SQL Proxy ---------------------------------------------------------
curl -sSLo /usr/local/bin/cloud-sql-proxy \
  https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.8.0/cloud-sql-proxy.linux.amd64
chmod +x /usr/local/bin/cloud-sql-proxy

cat > /etc/systemd/system/cloud-sql-proxy.service <<'SYSTEMD'
[Unit]
Description=Cloud SQL Proxy
After=network.target

[Service]
Type=simple
DynamicUser=yes
ExecStart=/usr/local/bin/cloud-sql-proxy --address 0.0.0.0 --port 5432 --private-ip ${cloudsql_instance_connection_name}
Restart=always
RestartSec=5
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes

[Install]
WantedBy=multi-user.target
SYSTEMD

# --- Cloud Run auth proxy (Python) -------------------------------------------
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
  python3 python3-requests jq ca-certificates

install -D -m 0555 /dev/stdin /usr/local/bin/cloudrun-auth-proxy.py <<'PYTHON'
${cloudrun_auth_proxy_py}
PYTHON

# Create a dedicated unprivileged user for the proxies
id -u cloudrun-proxy &>/dev/null || useradd -r -s /usr/sbin/nologin -M cloudrun-proxy

# --- Generate one systemd unit per entry in cloudrun_services ----------------
SERVICES_JSON='${cloudrun_services_json}'

echo "$SERVICES_JSON" | jq -r 'to_entries[] | "\(.key)\t\(.value.port)\t\(.value.url)"' | \
while IFS=$'\t' read -r name port url; do
  unit="/etc/systemd/system/cloudrun-proxy-$${name}.service"
  cat > "$unit" <<SYSTEMD
[Unit]
Description=Cloud Run Auth Proxy - $${name}
After=network.target

[Service]
Type=simple
User=cloudrun-proxy
Environment="PORT=$${port}"
Environment="TARGET_URL=$${url}"
ExecStart=/usr/local/bin/cloudrun-auth-proxy.py
Restart=always
RestartSec=5
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
SYSTEMD
done

systemctl daemon-reload
systemctl enable --now cloud-sql-proxy.service
for unit in /etc/systemd/system/cloudrun-proxy-*.service; do
  systemctl enable --now "$(basename "$unit")"
done
