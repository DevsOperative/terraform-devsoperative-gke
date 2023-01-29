data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

resource "google_compute_network" "vpc" {
  name                    = "${var.cluster_name}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "${var.cluster_name}-subnet"
  project       = var.project_id
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = "10.10.0.0/24"
}

module "gke" {
  source                          = "terraform-google-modules/kubernetes-engine/google"
  project_id                      = var.project_id
  name                            = "${var.cluster_name}"
  regional                        = false
  region                          = var.region
  zones                           = var.zones
  network                         = google_compute_network.vpc.name
  subnetwork                      = google_compute_subnetwork.subnet.name
  ip_range_pods                   = var.ip_range_pods
  ip_range_services               = var.ip_range_services
  create_service_account          = false
  service_account                 = var.service_account
  kubernetes_version              = "v1.21"
  release_channel                 = "STABLE"
  horizontal_pod_autoscaling      = true
  enable_vertical_pod_autoscaling = true
  remove_default_node_pool        = true

  node_pools = [
    {
      name               = "${var.cluster_name}-node-pool"
      machine_type       = var.machine_type
      min_count          = var.min_count
      max_count          = var.max_count
      disk_size_gb       = var.disk_size_gb
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      auto_repair        = true
      auto_upgrade       = true
      service_account    = var.service_account
      preemptible        = false
      initial_node_count = var.initial_node_count
    },
  ]
}