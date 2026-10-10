# Delete this file and the authentik entry in versions.tf after the first apply that removes Authentik.

removed {
  from = authentik_application.headlamp
  lifecycle {
    destroy = false
  }
}

removed {
  from = authentik_provider_oauth2.headlamp
  lifecycle {
    destroy = false
  }
}

removed {
  from = authentik_blueprint.recovery_flow
  lifecycle {
    destroy = false
  }
}

removed {
  from = authentik_user.cluster
  lifecycle {
    destroy = false
  }
}

removed {
  from = helm_release.authentik
  lifecycle {
    destroy = false
  }
}

removed {
  from = tls_private_key.authentik_ingress
  lifecycle {
    destroy = false
  }
}

removed {
  from = tls_self_signed_cert.authentik_ingress
  lifecycle {
    destroy = false
  }
}

provider "authentik" {
  url   = "https://127.0.0.1:1"
  token = "unused"
}
