variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "bastion_name" {
  description = "Name of the bastion host"
  type        = string
}

variable "zone" {
  description = "GCP zone for bastion host"
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
  description = "CloudSQL instance connection name"
  type        = string
}

variable "allowed_ssh_cidrs" {
  description = "CIDR ranges allowed to SSH to bastion"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "ssh_public_key" {
  description = "SSH public key for bastion access (from bastion-ssh-keys module)"
  type        = string
}

variable "courses_api_url" {
  description = "URL for beytra-api-courses Cloud Run service"
  type        = string
}

variable "topics_api_url" {
  description = "URL for beytra-api-topics Cloud Run service"
  type        = string
}

variable "assignments_api_url" {
  description = "URL for beytra-api-assignments Cloud Run service"
  type        = string
}

variable "concepts_api_url" {
  description = "URL for beytra-api-concepts Cloud Run service"
  type        = string
}

variable "questions_api_url" {
  description = "URL for beytra-api-questions Cloud Run service"
  type        = string
}

variable "students_api_url" {
  description = "URL for beytra-api-students Cloud Run service"
  type        = string
}

variable "maps_api_url" {
  description = "URL for beytra-api-maps Cloud Run service"
  type        = string
  default     = ""
}

# beytra-api-docs services (ports 8101-8103)
variable "documents_api_url" {
  description = "URL for beytra-api-documents Cloud Run service"
  type        = string
  default     = ""
}

variable "pages_api_url" {
  description = "URL for beytra-api-pages Cloud Run service"
  type        = string
  default     = ""
}

variable "media_api_url" {
  description = "URL for beytra-api-media Cloud Run service"
  type        = string
  default     = ""
}

# beytra-api-identity services (ports 8104-8106)
variable "users_api_url" {
  description = "URL for beytra-api-users Cloud Run service"
  type        = string
  default     = ""
}

variable "roles_api_url" {
  description = "URL for beytra-api-roles Cloud Run service"
  type        = string
  default     = ""
}

variable "permissions_api_url" {
  description = "URL for beytra-api-permissions Cloud Run service"
  type        = string
  default     = ""
}

# beytra-api-identity integrations services (ports 8107-8108)
variable "universities_api_url" {
  description = "URL for beytra-api-universities Cloud Run service"
  type        = string
  default     = ""
}

variable "integrations_api_url" {
  description = "URL for beytra-api-integrations Cloud Run service"
  type        = string
  default     = ""
}

variable "iap_tunnel_members" {
  description = "List of service accounts that need IAP tunnel access to bastion (e.g., serviceAccount:email@project.iam.gserviceaccount.com)"
  type        = list(string)
  default     = []
}
