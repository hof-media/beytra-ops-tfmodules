#!/bin/bash
set -e

# GitHub Actions Runner Startup Script
# Installs Docker, registers ephemeral runner, runs jobs, then shuts down

GITHUB_ORG="${github_org}"
GITHUB_REPO="${github_repo}"
RUNNER_LABELS="${runner_labels}"
PROJECT_ID="${project_id}"
TOKEN_SECRET="${token_secret}"
GITHUB_APP_ID="${github_app_id}"
GITHUB_INSTALLATION_ID="${github_installation_id}"

echo "========================================"
echo "GitHub Actions Runner Startup"
echo "========================================"
echo "Org: $GITHUB_ORG"
echo "Repo: $GITHUB_REPO"
echo "Labels: $RUNNER_LABELS"

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker ubuntu

# Install docker-compose
echo "Installing docker-compose..."
COMPOSE_VERSION="2.23.0"
curl -L "https://github.com/docker/compose/releases/download/v$${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install GitHub Actions runner
echo "Installing GitHub Actions runner..."
cd /opt
mkdir -p actions-runner
cd actions-runner

RUNNER_VERSION="2.311.0"
curl -o actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz -L \
  https://github.com/actions/runner/releases/download/v$${RUNNER_VERSION}/actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz
tar xzf ./actions-runner-linux-x64-$${RUNNER_VERSION}.tar.gz
chown -R ubuntu:ubuntu /opt/actions-runner

# Install jq for JSON parsing
echo "Installing jq..."
apt-get update && apt-get install -y jq

# Get GitHub App private key from Secret Manager
echo "Fetching GitHub App private key..."
PRIVATE_KEY=$(gcloud secrets versions access latest --secret="$TOKEN_SECRET" --project="$PROJECT_ID")

if [ -z "$PRIVATE_KEY" ]; then
  echo "ERROR: Failed to fetch private key from Secret Manager"
  exit 1
fi

# Save private key to file
echo "$PRIVATE_KEY" > /tmp/github-app.pem

# Generate JWT for GitHub App authentication
echo "Generating JWT token..."
NOW=$(date +%s)
IAT=$((NOW - 60))
EXP=$((NOW + 600))

# Create JWT header
HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Create JWT payload
PAYLOAD=$(echo -n "{\"iat\":$IAT,\"exp\":$EXP,\"iss\":\"$GITHUB_APP_ID\"}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Create signature
SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign /tmp/github-app.pem | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Combine into JWT
JWT="$HEADER.$PAYLOAD.$SIGNATURE"

# Get installation access token
echo "Getting installation access token..."
INSTALL_TOKEN_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $JWT" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/app/installations/$GITHUB_INSTALLATION_ID/access_tokens")

INSTALL_TOKEN=$(echo "$INSTALL_TOKEN_RESPONSE" | jq -r '.token')

if [ -z "$INSTALL_TOKEN" ] || [ "$INSTALL_TOKEN" = "null" ]; then
  echo "ERROR: Failed to get installation access token"
  echo "Response: $INSTALL_TOKEN_RESPONSE"
  exit 1
fi

# Get runner registration token
echo "Getting runner registration token..."
RUNNER_TOKEN_RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $INSTALL_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/$GITHUB_ORG/$GITHUB_REPO/actions/runners/registration-token")

RUNNER_TOKEN=$(echo "$RUNNER_TOKEN_RESPONSE" | jq -r '.token')

if [ -z "$RUNNER_TOKEN" ] || [ "$RUNNER_TOKEN" = "null" ]; then
  echo "ERROR: Failed to get runner registration token"
  echo "Response: $RUNNER_TOKEN_RESPONSE"
  exit 1
fi

# Clean up private key
rm -f /tmp/github-app.pem

echo "✅ Successfully obtained runner registration token"

# Configure runner (as ubuntu user)
echo "Configuring GitHub Actions runner..."
cd /opt/actions-runner
sudo -u ubuntu ./config.sh \
  --url "https://github.com/$GITHUB_ORG/$GITHUB_REPO" \
  --token "$RUNNER_TOKEN" \
  --name "$(hostname)" \
  --labels "$RUNNER_LABELS" \
  --work "_work" \
  --ephemeral \
  --unattended

# Run runner (blocks until job completes)
echo "Starting runner (ephemeral mode)..."
sudo -u ubuntu ./run.sh

# Runner exits after one job (ephemeral mode)
echo "Job complete. Runner exiting."

# Cleanup
cd /
rm -rf /opt/actions-runner

# Shutdown VM
echo "Shutting down VM..."
shutdown -h now
