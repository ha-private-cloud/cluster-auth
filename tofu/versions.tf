terraform {
  required_version = ">= 1.9.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30.0, < 3.0.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.0, < 4.0.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2026.5.0, < 2027.0.0"
    }
  }
}
