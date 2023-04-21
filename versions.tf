terraform {
  required_version = ">= 1.3.8"

  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "4.56.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}
