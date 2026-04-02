# CloudSQL PostgreSQL Module

This module creates a CloudSQL PostgreSQL instance for the Beytra project.

## Important Note

**This module does NOT create databases.** Databases are created via Flyway migrations in the `beytra-db` repository to ensure version control and consistency between local development and cloud deployment.

The Flyway migration `Migrations/beytra/V1__init_databases.sql` creates:
- `beytra-docs`
- `beytra-courses`
- `beytra-sms`
- `beytra-identity`

## Usage

```hcl
module "cloudsql" {
  source = "../../modules/cloud-sql"

  project_id  = "beytra-dev"
  region      = "us-central1"
  environment = "dev"

  # Dev environment settings (lowest cost)
  tier                = "db-f1-micro"
  disk_size           = 10
  availability_type   = "ZONAL"
  deletion_protection = false
  public_ip_enabled   = true

  # Authorized networks for development access
  authorized_networks = [
    {
      name = "dev-access"
      cidr = "0.0.0.0/0"  # Replace with your IP
    }
  ]

  labels = {
    environment = "dev"
    managed_by  = "terraform"
  }
}
```

## Outputs

- `instance_name` - CloudSQL instance name
- `instance_connection_name` - Connection name for Cloud SQL Proxy
- `public_ip` - Public IP address
- `private_ip` - Private IP address
- `user` - Database user name (beytra_user)
- `password` - Database password (sensitive)

## Cost Optimization

For development environments:
- Use `db-f1-micro` tier (~$7-8/month)
- Use `ZONAL` availability
- Set `disk_size` to minimum needed (10 GB)
- Disable `deletion_protection`

For production:
- Use `db-n1-standard-1` or higher
- Use `REGIONAL` availability for HA
- Enable `deletion_protection`
- Consider private IP only

## Security

Passwords are generated using `random_password` and should be stored in Secret Manager for application access.

## Next Steps After Apply

1. Run Flyway migrations to create databases:
   ```bash
   # In beytra-db repository, trigger GitHub Actions workflow
   # Or manually via Cloud SQL Proxy
   ```

2. Update Secret Manager with connection details
3. Configure Cloud Run jobs to use CloudSQL connection
