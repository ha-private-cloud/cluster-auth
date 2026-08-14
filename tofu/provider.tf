provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

# Talks to the real auth.talos.lab ingress (self-signed cert issued for
# that exact hostname, see tls.tf) rather than a kubectl port-forward , so
# this works unattended from the CI bastion, not just an interactive
# workstation session. Token is created in authentik.tf.
provider "authentik" {
  url      = "https://auth.talos.lab"
  insecure = true
  token    = random_password.authentik_bootstrap_token.result
}
