"""
GitHub Actions OIDC GitHub Runner Job Executor

Receives OIDC-authenticated requests from GitHub Actions and executes ephemeral GitHub runner Cloud Run Jobs.
Runner registration token is provided in the request payload.
"""
import os
import json
import logging
from datetime import datetime
from google.cloud import run_v2

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Environment variables
PROJECT_ID = os.getenv('PROJECT_ID')
REGION = os.getenv('REGION')
JOB_NAME = os.getenv('JOB_NAME')
RUNNER_NAME_PREFIX = os.getenv('RUNNER_NAME_PREFIX', 'github-runner')


def execute_gh_runner_job_request(job_id, repo_name, runner_token):
    """
    Execute a Cloud Run Job for ephemeral runner.

    Args:
        job_id: GitHub workflow job ID
        repo_name: Repository name
        runner_token: GitHub runner registration token (pre-generated)

    Returns:
        Execution name
    """
    # Initialize client at request time (not deploy time)
    jobs_client = run_v2.JobsClient()

    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    execution_name = f"{RUNNER_NAME_PREFIX}-{job_id}-{timestamp}"

    logger.info(f"Executing Cloud Run Job: {execution_name}")

    # Job path
    job_path = f"projects/{PROJECT_ID}/locations/{REGION}/jobs/{JOB_NAME}"

    # Create execution request with environment variable overrides
    # Pass the runner registration token directly
    request = run_v2.RunJobRequest(
        name=job_path,
        overrides=run_v2.RunJobRequest.Overrides(
            task_count=1,
            container_overrides=[
                run_v2.RunJobRequest.Overrides.ContainerOverride(
                    env=[
                        run_v2.EnvVar(name="JOB_ID", value=str(job_id)),
                        run_v2.EnvVar(name="EXECUTION_NAME", value=execution_name),
                        run_v2.EnvVar(name="RUNNER_TOKEN", value=runner_token),
                    ]
                )
            ]
        )
    )

    # Execute the job (async operation)
    operation = jobs_client.run_job(request=request)

    logger.info(f"Cloud Run Job execution started: {execution_name}")
    logger.info(f"Operation: {operation.operation.name}")

    return execution_name


def execute_gh_runner_job(request):
    """
    Cloud Function entry point.

    Handles OIDC-authenticated requests from GitHub Actions and executes GitHub runner jobs.
    Authentication is handled by Cloud Run IAM (ALLOW_INTERNAL_ONLY with IAM invoker role).
    Expects runner_token to be provided in the request payload.
    """
    # Parse payload
    try:
        payload = request.get_json()
    except Exception as e:
        logger.error(f"Failed to parse JSON: {e}")
        return ('Bad Request', 400)

    # Extract runner token from payload
    runner_token = payload.get('runner_token')
    if not runner_token:
        logger.error("No runner_token in payload")
        return ('Bad Request - runner_token required', 400)

    # Extract job info from workflow_job payload
    job = payload.get('workflow_job', {})
    if not job:
        logger.error("No workflow_job in payload")
        return ('Bad Request - workflow_job required', 400)

    job_id = job.get('id')
    job_name = job.get('name')
    labels = job.get('labels', [])

    logger.info(f"Received runner request: {job_name} (ID: {job_id})")
    logger.info(f"Labels: {labels}")

    # Check if job is for self-hosted runner
    if 'self-hosted' not in labels:
        logger.info("Job not for self-hosted runner, ignoring")
        return ('OK', 200)

    # Execute runner job
    try:
        execution_name = execute_gh_runner_job_request(job_id, job_name, runner_token)
        logger.info(f"Successfully started runner job: {execution_name}")
        return (json.dumps({
            'status': 'success',
            'execution': execution_name,
            'job_id': job_id
        }), 200)
    except Exception as e:
        logger.error(f"Failed to execute runner job: {e}")
        return (json.dumps({
            'status': 'error',
            'error': str(e)
        }), 500)
