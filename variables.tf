/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

variable "github_token" {
  description = "Token for ArgoCD to auth to GitHub"
}

variable "project_id" {
  description = "The project ID to host the cluster in"
}

variable "cluster_name" {
  description = "The default cluster name"
  default     = ""
}

variable "region" {
  description = "The region to host the cluster in"
}

variable "zones" {
  type        = list(string)
  description = "The zones to create the cluster."
}

variable "kubernetes_version" {
  description = "The initial version of GKE - If release_channel is supplied and auto update "
}

variable "release_channel" {
  description = "Release channel for GKE"
  default     = "STABLE"
}

variable "ip_range_pods" {
  description = "The secondary ip range to use for pods"
}

variable "ip_range_services" {
  description = "The secondary ip range to use for services"
}

variable "service_account" {
  description = "Service account to associate to the nodes in the cluster"
}

variable "skip_provisioners" {
  type        = bool
  description = "Flag to skip local-exec provisioners"
  default     = false
}

variable "enable_binary_authorization" {
  description = "Enable BinAuthZ Admission controller"
  default     = false
}

variable "machine_type" {
  type        = string
  description = "Type of the node compute engines."
}

variable "min_count" {
  type        = number
  description = "Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count."
  default     = 2
}

variable "max_count" {
  type        = number
  description = "Maximum number of nodes in the NodePool. Must be >= min_node_count."
  default     = 10
}

variable "disk_size_gb" {
  type        = number
  description = "Size of the node's disk."
}

variable "initial_node_count" {
  type        = number
  description = "The number of nodes to create in this cluster's default node pool."
  default     = 2
}

variable "backup_cron_schedule" {
  type    = string
  default = "0 2 * * *"
}

variable "backup_delete_lock_days" {
  type        = number
  default     = 7
  description = "Minimum number of days a backup will be stored"
}

variable "backup_retain_days" {
  type        = number
  default     = 60
  description = "Maximum number of days a backup will be stored before being deleted"
}

variable "backup_region" {
  type        = string
  default     = "us-east1"
  description = "What region the backups will be stored in"
}

variable "applicationset_name" {
  type = string
}

variable "applicationset_org" {
  type = string
}
