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

output "user" {
  description = "Database user name"
  value       = google_sql_user.beytra_user.name
}

output "password" {
  description = "Database password (sensitive)"
  value       = random_password.db_password.result
  sensitive   = true
}

output "instance_self_link" {
  description = "Self link to the CloudSQL instance"
  value       = google_sql_database_instance.main.self_link
}
