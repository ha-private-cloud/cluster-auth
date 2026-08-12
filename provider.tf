provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Requires `kubectl port-forward -n cluster-auth svc/authentik-server 9080:80`
# running locally. Token is created in authentik.tf.
provider "authentik" {
  url   = "http://localhost:9080"
  token = random_password.authentik_bootstrap_token.result
}
