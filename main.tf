data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

resource "google_compute_global_address" "gke_ingress" {
  name         = "global-external-ip"
  project      = var.project_id
  description  = "Static IP address reserved for ingress."
  address_type = "EXTERNAL"
  ip_version   = "IPV4"
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
  source                               = "terraform-google-modules/kubernetes-engine/google"
  project_id                           = var.project_id
  name                                 = var.cluster_name
  regional                             = false
  region                               = var.region
  zones                                = var.zones
  network                              = google_compute_network.vpc.name
  subnetwork                           = google_compute_subnetwork.subnet.name
  ip_range_pods                        = var.ip_range_pods
  ip_range_services                    = var.ip_range_services
  create_service_account               = false
  service_account                      = var.service_account
  kubernetes_version                   = var.kubernetes_version
  release_channel                      = var.release_channel
  horizontal_pod_autoscaling           = true
  enable_vertical_pod_autoscaling      = true
  remove_default_node_pool             = true
  monitoring_enable_managed_prometheus = false
  monitoring_enabled_components        = ["SYSTEM_COMPONENTS", "APISERVER", "CONTROLLER_MANAGER", "SCHEDULER"]
  logging_enabled_components           = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  enable_cost_allocation               = false
  gke_backup_agent_config              = true

  node_pools = [
    # CAUTION!! Changes to node pools could cause terraform to destroy the existing nodes.
    # Make sure to look at the plan before applying.
    {
      name               = "${var.cluster_name}-default-node-pool"
      machine_type       = var.machine_type
      min_count          = var.min_count
      max_count          = var.max_count
      local_ssd_count    = 0
      spot               = false
      disk_size_gb       = var.disk_size_gb
      disk_type          = "pd-standard"
      image_type         = "COS_CONTAINERD"
      enable_gcfs        = false
      enable_gvnic       = false
      auto_repair        = true
      auto_upgrade       = true
      service_account    = var.service_account
      preemptible        = false
      initial_node_count = var.initial_node_count
    },
  ]
}

resource "google_gke_backup_backup_plan" "default-plan" {
  name     = "default-plan"
  project  = var.project_id
  cluster  = module.gke.cluster_id
  location = var.backup_region
  retention_policy {
    backup_delete_lock_days = var.backup_delete_lock_days
    backup_retain_days      = var.backup_retain_days
  }
  backup_schedule {
    cron_schedule = var.backup_cron_schedule
  }
  backup_config {
    include_volume_data = true
    include_secrets     = true
    all_namespaces      = true
  }
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.endpoint}"
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  namespace        = "argocd"
  create_namespace = true
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"

  lifecycle {
    ignore_changes = all
  }
}

provider "kubectl" {
  host                   = module.gke.endpoint
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  token                  = data.google_client_config.default.access_token
  load_config_file       = false
}

resource "kubectl_manifest" "gh_token" {
  yaml_body = <<YAML
apiVersion: v1
data:
  token: ${var.github_token}
kind: Secret
metadata:
  creationTimestamp: null
  name: github-token
  namespace: argocd
YAML
}

resource "kubectl_manifest" "applicationset" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: ${var.applicationset_name}
  namespace: argocd
spec:
  generators:
  - scmProvider:
      cloneProtocol: https
      filters:
      - pathsExist: [delivery/chart/]
        labelMatch: deploy-ok
      github:
        # The GitHub organization to scan.
        organization: ${var.applicationset_org}
        # Reference to a Secret containing an access token. (optional)
        tokenRef:
          secretName: github-token
          key: token
  template:
    metadata:
      name: '{{ repository }}'
    spec:
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
      source:
        repoURL: '{{ url }}'
        targetRevision: '{{ branch }}'
        path: delivery/chart/
      project: default
      destination:
        server: https://kubernetes.default.svc
        namespace: default
YAML
}
