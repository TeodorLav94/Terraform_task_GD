# modules/compute-image/main.tf
locals {
  startup_script_builder = <<-EOT
    #!/bin/bash
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -y
    sudo apt-get install -y apache2 curl 

    sudo systemctl stop apache2
    sudo systemctl enable apache2
    sudo systemctl start apache2
    
    # Adaugă un fișier index generic pentru a fi siguri că Apache merge
    echo "<html><body><h1>Image Base Setup Complete. Index will be updated by Scale Set.</h1></body></html>" | sudo tee /var/www/html/index.html

    if systemctl is-active --quiet apache2; then
        echo "Apache started successfully."
    else
        echo "Apache failed to start!"
        exit 1
    fi
    EOT
}


resource "google_compute_instance" "builder_vm" {
  name         = "image-builder-vm"
  machine_type = "e2-micro"
  zone         = var.zone
  tags         = ["app-instance", "http-lb-target"] 

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    subnetwork = var.subnet_self_link
    access_config {} 
  }

  metadata = {
    startup-script = local.startup_script_builder
  }

  provisioner "local-exec" {
    command = "sleep 120"
  }
}

resource "null_resource" "stop_builder_vm" { 
  depends_on = [google_compute_instance.builder_vm] 

  provisioner "local-exec" { 
    command = "gcloud compute instances stop ${google_compute_instance.builder_vm.name} --zone ${var.zone} --quiet; sleep 60" 
  } 
}

resource "google_compute_image" "custom_image" {
  name            = "webserver-base-image-v1" 
  source_disk     = google_compute_instance.builder_vm.boot_disk[0].source
  family          = "webservers"
  
  depends_on      = [null_resource.stop_builder_vm] 
}

output "image_self_link" {
  value = google_compute_image.custom_image.self_link
}
