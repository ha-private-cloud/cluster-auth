resource "random_password" "authentik_secret_key" {
  length  = 50
  special = false
}

resource "random_password" "authentik_bootstrap_password" {
  length  = 24
  special = false
}

resource "random_password" "authentik_bootstrap_token" {
  length  = 40
  special = false
}

resource "kubernetes_secret" "authentik_bootstrap" {
  metadata {
    name      = "authentik-bootstrap"
    namespace = kubernetes_namespace.cluster_auth.metadata[0].name
  }

  data = {
    AUTHENTIK_BOOTSTRAP_EMAIL    = var.authentik_bootstrap_email
    AUTHENTIK_BOOTSTRAP_PASSWORD = random_password.authentik_bootstrap_password.result
    # Used by the authentik Terraform provider (see provider.tf) to manage Authentik declaratively.
    AUTHENTIK_BOOTSTRAP_TOKEN = random_password.authentik_bootstrap_token.result
  }
}

resource "helm_release" "authentik" {
  name       = "authentik"
  repository = "https://charts.goauthentik.io"
  chart      = "authentik"
  version    = var.authentik_chart_version
  namespace  = kubernetes_namespace.cluster_auth.metadata[0].name

  values = [
    templatefile("${path.module}/../values/authentik.yaml.tftpl", {
      secret_key              = random_password.authentik_secret_key.result
      postgres_host           = "${kubernetes_service.postgres.metadata[0].name}.${kubernetes_namespace.cluster_auth.metadata[0].name}.svc.cluster.local"
      postgres_db             = "authentik"
      postgres_user           = "authentik"
      postgres_password       = random_password.postgres.result
      bootstrap_secret_name   = kubernetes_secret.authentik_bootstrap.metadata[0].name
      hostname                = var.authentik_hostname
      ingress_tls_secret_name = var.ingress_tls_secret_name
    })
  ]

  depends_on = [kubernetes_stateful_set_v1.postgres]
}
