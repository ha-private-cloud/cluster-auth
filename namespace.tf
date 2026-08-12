resource "kubernetes_namespace" "cluster_auth" {
  metadata {
    name = var.namespace
  }
}
