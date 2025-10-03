variable "region" {
  description = "Regiunea GCP"
  type        = string
}

variable "allowed_ip_ranges" {
  description = "Lista de CIDR-uri permise pentru a accesa Load Balancer-ul."
  type        = list(string)
  default     = ["0.0.0.0/0"] 
}
