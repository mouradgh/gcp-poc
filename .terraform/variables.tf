# GCP credentials, stored in the HCP Terraform UI
variable "gcp-creds" {
  default     = ""
}

# GCP Project ID
variable "project" {
  type        = string
  default     = "fourth-walker-449914-t1"
  description = "GCP Project ID"
}

# Default region
variable "region" {
  type        = string
  default     = "europe-west9"
  description = "GCP Region - Geographic placement of the data"
}

# Alloy DB user
variable "database_user" {
  description = "Database user name"
  type        = string
  default     = "alloydb_user"
}

# Alloy DB password, stored in the HCP Terraform UI
variable "database_password" {
  description = "Database password"
  type        = string
  sensitive   = true
} 