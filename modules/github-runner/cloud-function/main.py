"""
GitHub Actions Webhook Receiver & Runner Manager

Receives GitHub workflow_job webhooks and starts ephemeral runner VMs.
"""
import os
import hmac
import hashlib
import json
import logging
from datetime import datetime
from google.cloud import compute_v1, secretmanager
from google.cloud.compute_v1.types import InsertInstanceRequest

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables
PROJECT_ID = os.getenv('PROJECT_ID')
ZONE = os.getenv('ZONE')
INSTANCE_TEMPLATE = os.getenv('INSTANCE_TEMPLATE')
WEBHOOK_SECRET_NAME = os.getenv('WEBHOOK_SECRET_NAME')
RUNNER_NAME_PREFIX = os.getenv('RUNNER_NAME_PREFIX', 'github-runner')

# Clients
compute_client = compute_v1.InstancesClient()
secret_client = secretmanager.SecretManagerServiceClient()


def get_webhook_secret():
    """Fetch webhook secret from Secret Manager."""
    name = f"projects/{PROJECT_ID}/secrets/{WEBHOOK_SECRET_NAME}/versions/latest"
    response = secret_client.access_secret_version(request={"name": name})
    return response.payload.data.decode('UTF-8')


def verify_signature(payload, signature_header):
    """Verify GitHub webhook signature."""
    webhook_secret = get_webhook_secret()
    expected_signature = 'sha256=' + hmac.new(
        webhook_secret.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()

    return hmac.compare_digest(expected_signature, signature_header)


def create_runner_vm(job_id, repo_name):
    """
    Create a new ephemeral runner VM.

    Args:
        job_id: GitHub workflow job ID
        repo_name: Repository name

    Returns:
        VM instance name
    """
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    instance_name = f"{RUNNER_NAME_PREFIX}-{job_id}-{timestamp}"

    logger.info(f"Creating runner VM: {instance_name}")

    # Create instance from template using source_instance_template
    template_url = f"projects/{PROJECT_ID}/global/instanceTemplates/{INSTANCE_TEMPLATE}"

    instance = compute_v1.Instance()
    instance.name = instance_name

    # Add job metadata labels
    instance.labels = {
        'github-job-id': str(job_id),
        'repo': repo_name.replace('/', '-'),
        'created-by': 'github-webhook'
    }

    # Create VM from template using InsertInstanceRequest
    request = InsertInstanceRequest(
        project=PROJECT_ID,
        zone=ZONE,
        instance_resource=instance,
        source_instance_template=template_url
    )

    operation = compute_client.insert(request=request)

    logger.info(f"VM creation started: {instance_name}")
    return instance_name


def handle_webhook(request):
    """
    Cloud Function entry point.

    Handles GitHub workflow_job webhooks and starts runner VMs.
    """
    # Verify signature
    signature = request.headers.get('X-Hub-Signature-256', '')
    if not verify_signature(request.get_data(), signature):
        logger.error("Invalid webhook signature")
        return ('Forbidden', 403)

    # Parse payload
    try:
        payload = request.get_json()
    except Exception as e:
        logger.error(f"Failed to parse JSON: {e}")
        return ('Bad Request', 400)

    # Check event type
    event_type = request.headers.get('X-GitHub-Event', '')
    if event_type != 'workflow_job':
        logger.info(f"Ignoring event type: {event_type}")
        return ('OK', 200)

    # Check action
    action = payload.get('action', '')
    if action != 'queued':
        logger.info(f"Ignoring action: {action}")
        return ('OK', 200)

    # Extract job info
    job = payload.get('workflow_job', {})
    job_id = job.get('id')
    job_name = job.get('name')
    repo_name = payload.get('repository', {}).get('full_name')
    labels = job.get('labels', [])

    logger.info(f"Job queued: {job_name} (ID: {job_id})")
    logger.info(f"Repository: {repo_name}")
    logger.info(f"Labels: {labels}")

    # Check if job is for self-hosted runner
    if 'self-hosted' not in labels:
        logger.info("Job not for self-hosted runner, ignoring")
        return ('OK', 200)

    # Create runner VM
    try:
        instance_name = create_runner_vm(job_id, repo_name)
        logger.info(f"Successfully created runner VM: {instance_name}")
        return (json.dumps({
            'status': 'success',
            'instance': instance_name,
            'job_id': job_id
        }), 200)
    except Exception as e:
        logger.error(f"Failed to create runner VM: {e}")
        return (json.dumps({
            'status': 'error',
            'error': str(e)
        }), 500)
