# main.tf

locals {
  region = var.gcp_region
  zone   = var.gcp_zone
}

module "network" {
  source = "./modules/network"
  region = local.region
}

module "compute" {
  source           = "./modules/compute"
  zone             = local.zone
  subnet_self_link = module.network.subnet_self_link
}

module "compute_autoscaler" {
  source           = "./modules/compute-autoscaler"
  zone             = local.zone
  subnet_self_link = module.network.subnet_self_link
  image_self_link  = module.compute.image_self_link
}

output "load_balancer_ip" {
  description = "Adresa IP publică a Load Balancer-ului"
  value       = module.compute_autoscaler.load_balancer_ip
}
