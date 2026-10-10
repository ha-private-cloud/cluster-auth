locals {
  group_cluster_roles = {
    "cluster-admins"  = "cluster-admin"
    "cluster-editors" = "edit"
    "cluster-viewers" = "view"
  }
}

resource "kubernetes_cluster_role_binding" "group" {
  for_each = local.group_cluster_roles

  metadata {
    name = "oidc-group-${each.key}"
  }

  subject {
    kind      = "Group"
    name      = "${var.oidc_groups_prefix}${each.key}"
    api_group = "rbac.authorization.k8s.io"
  }

  role_ref {
    kind      = "ClusterRole"
    name      = each.value
    api_group = "rbac.authorization.k8s.io"
  }
}
