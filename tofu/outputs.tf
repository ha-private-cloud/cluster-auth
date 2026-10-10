output "headlamp_oidc_client_id" {
  value = "headlamp"
}

output "headlamp_oidc_issuer_url" {
  value = var.auth_api_issuer_url
}

output "headlamp_oidc_client_secret" {
  value     = random_password.headlamp_client_secret.result
  sensitive = true
}
