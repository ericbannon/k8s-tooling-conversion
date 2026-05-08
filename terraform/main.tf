terraform {
  required_providers {
    kubectl = {
      source  = "alekc/kubectl"
      version = "2.1.3"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.15.0"
    }
  }
}
