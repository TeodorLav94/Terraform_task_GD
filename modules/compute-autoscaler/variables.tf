# modules/compute-autoscaler/variables.tf
variable "zone" {
  type        = string
}

variable "subnet_self_link" {
  type        = string
}

variable "image_self_link" {
  type        = string
}
