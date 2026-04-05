# CloudSQL Module Outputs

output "instance_name" {
  description = "CloudSQL instance name"
  value       = google_sql_database_instance.main.name
}

output "instance_connection_name" {
  description = "CloudSQL instance connection name (project:region:instance)"
  value       = google_sql_database_instance.main.connection_name
}

output "public_ip" {
  description = "Public IP address of CloudSQL instance"
  value       = try(google_sql_database_instance.main.public_ip_address, null)
}

output "private_ip" {
  description = "Private IP address of CloudSQL instance"
  value       = try(google_sql_database_instance.main.private_ip_address, null)
}

output "users" {
  description = "Map of DB user name => user name (identity map for convenience)"
  value       = { for k, u in google_sql_user.users : k => u.name }
}

output "password_secret_ids" {
  description = "Map of DB user name => Secret Manager secret ID holding that user's password"
  value       = { for k, s in google_secret_manager_secret.db_password : k => s.secret_id }
}

output "instance_self_link" {
  description = "Self link to the CloudSQL instance"
  value       = google_sql_database_instance.main.self_link
}
