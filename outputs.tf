output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}

output "location" {
  value = module.gke.location
}

output "master_kubernetes_version" {
  description = "Kubernetes version of the master"
  value       = module.gke.master_version
}

output "region" {
  description = "The region in which the cluster resides"
  value       = module.gke.region
}

output "project_id" {
  description = "The project ID the cluster is in"
  value       = var.project_id
}