variable "gcp_region" {
  description = "Regiunea GCP pentru resurse."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "Zona GCP pentru VM-uri."
  type        = string
  default     = "us-central1-a"
}
