variable "gcp-creds" {
  default     = ""
}

variable "project" {
  type        = string
  default     = "fourth-walker-449914-t1"
  description = "GCP Project ID"
}

variable "region" {
  type        = string
  default     = "europe-west9"
  description = "GCP Region - Geographic placement of the data"
}
