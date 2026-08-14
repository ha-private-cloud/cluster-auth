# Same URL the "authentik" provider uses (see provider.tf); the http data
# source below needs it directly since recovery links have no provider resource.
locals {
  authentik_api_url = "http://localhost:9080"
}

data "terraform_remote_state" "cluster_rbac" {
  backend = "local"

  config = {
    path = "${path.module}/../../cluster-rbac/tofu/terraform.tfstate"
  }
}

# No password set , account can't log in until the recovery link below is used to set one.
resource "authentik_user" "cluster" {
  for_each = toset(data.terraform_remote_state.cluster_rbac.outputs.usernames)

  username  = each.value
  name      = each.value
  email     = "${each.value}@${var.authentik_hostname}"
  is_active = true
}

# No provider resource for generating recovery links, so this POSTs to the
# REST API directly; re-running `tofu apply` mints a fresh link each time.
# Requires the default brand's recovery flow to be set, or this API call 404s.
data "http" "user_recovery_link" {
  for_each = authentik_user.cluster

  url    = "${local.authentik_api_url}/api/v3/core/users/${each.value.id}/recovery/"
  method = "POST"

  depends_on = [authentik_brand.default]

  request_headers = {
    Authorization = "Bearer ${random_password.authentik_bootstrap_token.result}"
    Content-Type  = "application/json"
    Accept        = "application/json"
  }

  request_body = jsonencode({})
}
