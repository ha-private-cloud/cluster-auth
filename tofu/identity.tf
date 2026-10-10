resource "random_password" "headlamp_client_secret" {
  length  = 48
  special = false
}

resource "kubernetes_secret" "cluster_identity" {
  metadata {
    name      = var.identity_secret_name
    namespace = var.auth_api_namespace
  }

  data = {
    AUTH_API_HEADLAMP_CLIENT_SECRET = random_password.headlamp_client_secret.result
  }
}

resource "kubernetes_annotations" "auth_api_rollout" {
  api_version = "apps/v1"
  kind        = "Deployment"

  metadata {
    name      = var.auth_api_deployment
    namespace = var.auth_api_namespace
  }

  template_annotations = {
    "clusterkeep.dev/cluster-identity" = nonsensitive(sha256(jsonencode(kubernetes_secret.cluster_identity.data)))
  }
}
