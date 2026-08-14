output "authentik_url" {
  description = "URL for the Authentik UI once DNS/hosts is configured."
  value       = "https://${var.authentik_hostname}"
}

output "authentik_bootstrap_email" {
  value = var.authentik_bootstrap_email
}

output "authentik_bootstrap_password" {
  value     = random_password.authentik_bootstrap_password.result
  sensitive = true
}

output "headlamp_oidc_issuer_url" {
  description = "OIDC issuer URL for Headlamp's config.oidc.issuerURL, in cluster-config."
  value       = "https://${var.authentik_hostname}/application/o/${authentik_application.headlamp.slug}/"
}

output "headlamp_oidc_client_id" {
  value = authentik_provider_oauth2.headlamp.client_id
}

output "headlamp_oidc_client_secret" {
  value     = random_password.headlamp_oidc_client_secret.result
  sensitive = true
}

output "authentik_ingress_ca_cert_pem" {
  description = "Self-signed cert for auth.talos.lab (it's its own CA) , feed this into proxmox-tofu/talos-oidc-patch.yaml's oidc-ca-file."
  value       = tls_self_signed_cert.authentik_ingress.cert_pem
}

output "user_recovery_links" {
  description = "One-time links for each cluster-rbac user to set their password. Re-run `tofu apply` to mint fresh links (old ones expire)."
  value = {
    for username, resp in data.http.user_recovery_link :
    # Swap the port-forward host Authentik used to build the link for the real external hostname.
    username => try(
      replace(jsondecode(resp.response_body).link, local.authentik_api_url, "https://${var.authentik_hostname}"),
      null
    )
  }
  sensitive = true
}
