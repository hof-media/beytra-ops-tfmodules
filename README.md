# beytra-ops-tfmodules

Shared Terraform modules for the Beytra platform. Consumed by each project's `.iac/` directory via git tags.

## Usage

```hcl
module "my_service" {
  source = "github.com/hof-media/beytra-ops-tfmodules//modules/cloud-run-service?ref=v1.0.0"
  # ...
}
```

## Modules

| Module | Description |
|--------|-------------|
| `cloud-run-service` | Cloud Run service with scaling, CPU, and billing config |
| `cloud-run-job` | Cloud Run Job for migrations and batch tasks |
| `cloud-sql` | PostgreSQL CloudSQL instance |
| `gcs-buckets` | GCS bucket provisioning with lifecycle rules |
| `memorystore-redis` | Redis cache instance |
| `secret-shell` | Secret Manager container (no values — shell only) |
| `service-account` | Service account with custom least-privilege IAM role |
| `vpc-network` | VPC network with Cloud NAT |
| `vpc-connector` | Serverless VPC connector for Cloud Run |
| `vpc-peering` | VPC peering for Google-managed services |
| `load-balancer` | Global HTTPS load balancer with SSL |
| `cloud-armor` | Cloud Armor DDoS/WAF policy |
| `cloud-dns` | Cloud DNS zone and records |
| `pubsub-push` | Pub/Sub topic with push subscription |
| `cloud-workflow` | Cloud Workflows for event-driven pipelines |
| `bastion-host` | Bastion VM for private DB access |
| `bastion-ssh-keys` | SSH key management for bastion |
| `bastion-access-iam` | IAM bindings for bastion tunnel access |

## Roles

`roles/permissions.tf` defines canonical permission sets for common service account patterns. Import as a module:

```hcl
module "roles" {
  source = "github.com/hof-media/beytra-ops-tfmodules//roles?ref=v1.0.0"
}

module "my_sa" {
  source = "github.com/hof-media/beytra-ops-tfmodules//modules/service-account?ref=v1.0.0"
  custom_role_permissions = module.roles.cloud_run_runtime_permissions
}
```

## Versioning

Follows semantic versioning via git tags (`v1.0.0`, `v1.1.0`, etc.). Pin to a specific version in your project's `.iac/`:

```hcl
source = "github.com/hof-media/beytra-ops-tfmodules//modules/cloud-run-service?ref=v1.0.0"
```
