# modules/compute-autoscaler/main.tf
locals {
  startup_script_scale_set = <<-EOT
    #!/bin/bash
    SERVER_HOSTNAME=$(hostname)
    SERVER_IP=$(/usr/bin/curl -f -s -H "Metadata-Flavor:Google" http://metadata.google.internal/computeMetadata/v1/instance/network-interfaces/0/ip)
    echo "<html>
    <head>
        <title>Load Balancer Test</title>
        <style>
             # ...
        </style>
    </head>
    <body>
        <h1>Done!</h1>
        <div class=\"ip-display\"> 
            <h2>Nume de Host: $SERVER_HOSTNAME</h2>
            <h2>Unique Internal IP: $SERVER_IP</h2>
        </div>
        <p>Refresh page for changing instances.</p>
    </body>
    </html>" | sudo tee /var/www/html/index.html
    
    sudo systemctl restart apache2
    EOT
}

resource "google_compute_instance_template" "app_template" {
  name_prefix  = "app-template-"
  machine_type = "e2-micro"
  tags         = ["app-instance", "http-lb-target"]

  lifecycle {
    create_before_destroy = true
  }

  disk {
    source_image = var.image_self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    subnetwork = var.subnet_self_link
  }

  metadata = {
    startup-script = local.startup_script_scale_set
  }
}

resource "google_compute_instance_group_manager" "app_mig" {
  name     = "app-mig"
  zone     = var.zone
  target_size = 3

  base_instance_name = "app-web-v1"
  
  version {
    instance_template = google_compute_instance_template.app_template.self_link
    name              = "primary" 
  }

  named_port {
    name = "http" 
    port = 80    
  }
}

resource "google_compute_health_check" "http_health_check" {
  name = "http-lb-health-check"
  http_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "app_backend" {
  name        = "app-backend-service"
  protocol    = "HTTP"
  port_name   = "http"
  timeout_sec = 10
  health_checks = [google_compute_health_check.http_health_check.self_link]

  backend {
    group = google_compute_instance_group_manager.app_mig.instance_group
  }

  lifecycle {
    ignore_changes = [backend] 
  }
}

resource "google_compute_url_map" "app_url_map" {
  name            = "app-url-map"
  default_service = google_compute_backend_service.app_backend.self_link
}

resource "google_compute_target_http_proxy" "app_http_proxy" {
  name    = "app-http-proxy"
  url_map = google_compute_url_map.app_url_map.self_link
}

resource "google_compute_global_forwarding_rule" "http_forwarding_rule" {
  name       = "app-http-forwarding-rule"
  target     = google_compute_target_http_proxy.app_http_proxy.self_link
  port_range = "80"
}

output "load_balancer_ip" {
  value = google_compute_global_forwarding_rule.http_forwarding_rule.ip_address
}
