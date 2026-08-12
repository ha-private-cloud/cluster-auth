data "authentik_flow" "default_authorization_flow" {
  slug = "default-provider-authorization-implicit-consent"
}

data "authentik_flow" "default_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_property_mapping_provider_scope" "headlamp_scopes" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-profile",
  ]
}

# authentik's bootstrap-generated cert; used as signing_key below so ID
# tokens come out RS256 instead of HS256, which Headlamp's OIDC library requires.
data "authentik_certificate_key_pair" "self_signed" {
  name = "authentik Self-signed Certificate"
}

resource "random_password" "headlamp_oidc_client_secret" {
  length  = 40
  special = false
}

resource "authentik_provider_oauth2" "headlamp" {
  name      = "headlamp"
  client_id = "headlamp"
  # Generated here (not left to the chart default) so it can be handed to cluster-config's Headlamp config.
  client_secret = random_password.headlamp_oidc_client_secret.result

  authorization_flow = data.authentik_flow.default_authorization_flow.id
  invalidation_flow  = data.authentik_flow.default_invalidation_flow.id
  property_mappings  = data.authentik_property_mapping_provider_scope.headlamp_scopes.ids

  # grant_types is "computed", so omitting it disables authorization_code/refresh_token
  # rather than allowing everything like the other list attributes here — must be set explicitly.
  grant_types = ["authorization_code", "refresh_token"]
  signing_key = data.authentik_certificate_key_pair.self_signed.id

  allowed_redirect_uris = [
    {
      matching_mode = "strict"
      url           = "https://${var.headlamp_hostname}/oidc-callback"
    }
  ]
}

resource "authentik_application" "headlamp" {
  name              = "Headlamp"
  slug              = "headlamp"
  protocol_provider = authentik_provider_oauth2.headlamp.id
}
