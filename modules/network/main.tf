resource "google_compute_network" "vpc_network" {
  name                    = "tlav-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "app_subnet" {
  name          = "tlav-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.region
  network       = google_compute_network.vpc_network.id
}

resource "google_compute_firewall" "http_ingress_lb" {
  name    = "allow-http-lb-ingress"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = var.allowed_ip_ranges 
  target_tags   = ["http-lb-target"]
}

resource "google_compute_firewall" "health_check_internal" {
  name    = "allow-health-check-internal"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  target_tags   = ["app-instance"]
}

output "subnet_self_link" {
  value = google_compute_subnetwork.app_subnet.self_link
}
