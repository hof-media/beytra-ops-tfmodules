# Custom IAM Role Definitions

Reference permission sets for common service account patterns in the Beytra platform.
These are used as `custom_role_permissions` inputs to the `service-account` module.

## Role Patterns

### cloud-run-runtime
Permissions for a Cloud Run service at runtime (read secrets, connect to DB, access storage).

### cloud-run-deployer
Permissions for CI/CD pipelines that deploy Cloud Run services.

### gcs-signer
Permissions for services that generate GCS signed URLs.

## Usage

These are not standalone Terraform resources. They are reference lists used with the service-account module:

```hcl
module "my_sa" {
  source = "github.com/hof-media/beytra-ops-tfmodules//modules/service-account?ref=v1.0.0"
  # ...
  custom_role_permissions = local.cloud_run_runtime_permissions
}
```
