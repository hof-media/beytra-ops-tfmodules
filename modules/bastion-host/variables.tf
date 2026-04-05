variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "bastion_name" {
  description = "Name of the bastion host"
  type        = string
}

variable "zone" {
  description = "GCP zone for bastion host. Downstream dev tunnels hardcode this via docker-compose — changing it breaks every developer's tunnels."
  type        = string
}

variable "network_id" {
  description = "ID of the VPC network"
  type        = string
}

variable "machine_type" {
  description = "Machine type for bastion host"
  type        = string
  default     = "e2-micro"
}

variable "cloudsql_instance_connection_name" {
  description = "CloudSQL instance connection name (project:region:instance)"
  type        = string
}

variable "cloudrun_services" {
  description = "Cloud Run services proxied through the bastion. Map key = short service name (used for systemd unit + bastion-side port); value = { port, url }. Bastion SA automatically granted roles/run.invoker on each service_name listed in invoker_service_names."
  type = map(object({
    port = number
    url  = string
  }))
  default = {}
}

variable "invoker_service_names" {
  description = "List of Cloud Run service NAMES (not URLs) that the bastion SA needs roles/run.invoker on. Typically the same set of values as the keys of cloudrun_services but prefixed with 'beytra-api-'. Passed explicitly because the module can't parse service names from URLs reliably."
  type = list(object({
    service_name = string
    region       = string
  }))
  default = []
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}
