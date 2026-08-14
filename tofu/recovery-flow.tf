resource "authentik_blueprint" "recovery_flow" {
  name    = "recovery-flow"
  content = file("${path.module}/../blueprints/recovery-flow.yaml")
}

# Applying a blueprint just updates the blueprint instance record , Authentik
# processes its actual content (creating the flow/stage objects) in a
# background task, not synchronously as part of that API call. Without this
# wait, the data source below can run before that background task finishes
# and find nothing, even though depends_on already waited for the blueprint
# resource itself to report done.
resource "time_sleep" "recovery_flow_blueprint" {
  depends_on      = [authentik_blueprint.recovery_flow]
  create_duration = "15s"
}

data "authentik_flow" "recovery" {
  slug = "default-recovery-flow"

  depends_on = [time_sleep.recovery_flow_blueprint]
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
