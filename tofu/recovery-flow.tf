resource "authentik_blueprint" "recovery_flow" {
  name    = "recovery-flow"
  content = file("${path.module}/../blueprints/recovery-flow.yaml")
}

# The provider's create/update just PUTs the blueprint instance's content ,
# it never actually applies it (confirmed: no flow/stage gets created, no
# background task runs). Authentik has a separate apply endpoint for that,
# same POST-with-side-effect pattern users.tf already uses for recovery links.
data "http" "recovery_flow_apply" {
  url      = "${local.authentik_api_url}/api/v3/managed/blueprints/${authentik_blueprint.recovery_flow.id}/apply/"
  method   = "POST"
  insecure = true

  depends_on = [authentik_blueprint.recovery_flow]

  request_headers = {
    Authorization = "Bearer ${random_password.authentik_bootstrap_token.result}"
    Accept        = "application/json"
  }
}

data "authentik_flow" "recovery" {
  slug = "default-recovery-flow"

  depends_on = [data.http.recovery_flow_apply]
}

resource "authentik_brand" "default" {
  domain              = "authentik-default"
  default             = true
  branding_title      = "authentik"
  branding_logo       = "/static/dist/assets/icons/icon_left_brand.svg"
  branding_favicon    = "/static/dist/assets/icons/icon.png"
  flow_authentication = data.authentik_flow.default_authentication.id
  flow_invalidation   = data.authentik_flow.default_invalidation.id
  flow_user_settings  = data.authentik_flow.default_user_settings.id
  flow_recovery       = data.authentik_flow.recovery.id
}

data "authentik_flow" "default_authentication" {
  slug = "default-authentication-flow"
}

data "authentik_flow" "default_invalidation" {
  slug = "default-invalidation-flow"
}

data "authentik_flow" "default_user_settings" {
  slug = "default-user-settings-flow"
}
