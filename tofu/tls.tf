# ingress-nginx's default cert (CN=ingress.local) doesn't match auth.talos.lab,
# which the Talos apiserver's OIDC hostname verification requires exactly
# (no skip-verify option). So Authentik gets its own self-signed cert here instead.
resource "tls_private_key" "authentik_ingress" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "authentik_ingress" {
  private_key_pem = tls_private_key.authentik_ingress.private_key_pem

  subject {
    common_name = var.authentik_hostname
  }

  dns_names = [var.authentik_hostname]

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_secret" "authentik_ingress_tls" {
  metadata {
    name      = "authentik-ingress-tls"
    namespace = kubernetes_namespace.cluster_auth.metadata[0].name
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = tls_self_signed_cert.authentik_ingress.cert_pem
    "tls.key" = tls_private_key.authentik_ingress.private_key_pem
  }
}
