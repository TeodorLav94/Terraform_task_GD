terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
  backend "gcs" {
    bucket = "terraform-tlav"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "gd-gcp-internship-devops"
  region  = var.gcp_region
  zone    = var.gcp_zone
}
