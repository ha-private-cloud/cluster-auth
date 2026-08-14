# cluster-auth

Username/password login for the cluster, replacing Headlamp's bearer-token
login. Installs, via OpenTofu, into the Talos cluster provisioned in
`proxmox-tofu`:

- **Postgres** on the `nfs-csi` StorageClass
  from `cluster-config`.
- **Authentik** , OIDC identity provider, backed by the Postgres above,
  exposed at `https://auth.talos.lab` through the existing ingress-nginx.
- An OAuth2 provider + application for Headlamp, created declaratively via
  the `goauthentik/authentik` Terraform provider.

Headlamp itself only speaks OIDC or bearer tokens (no native username/
password support), which is why Authentik sits in front of it.

## Prerequisites

- `tofu` (OpenTofu)
- A working kubeconfig from the cluster bootstrap
- `cluster-config` already applied

## Usage

All `.tf` files live under `tofu/` , run OpenTofu from inside it, not the
repo root:
```bash
cd tofu
```

Add this to your tfvars, pointing to your kubeconfig:
```bash
kubeconfig_path = ""
```

The `authentik` provider talks to Authentik's API directly.

```bash
export KUBECONFIG=../../proxmox-tofu/_out/kubeconfig
kubectl port-forward -n cluster-auth svc/authentik-server 9080:80
```

Then:

```bash
tofu plan
tofu apply
```

On a from-scratch apply, Postgres and Authentik need to exist before the
`authentik` provider can reach anything , if you run everything in one
shot and the OIDC resources fail because Authentik isn't up yet, just
re-run `tofu apply` once Authentik's pods are `Running`.

## Accessing Authentik

1. Add to `/etc/hosts` (same pattern as Headlamp):

   ```
   192.168.0.16  auth.talos.lab
   ```

2. Browse to `https://auth.talos.lab` , self-signed cert warning expected
3. Log in with the bootstrap admin account (from `tofu/`):

   ```bash
   export KUBECONFIG=../../proxmox-tofu/_out/kubeconfig
   tofu output authentik_bootstrap_email
   tofu output -raw authentik_bootstrap_password
   ```

## Notes

- All generated credentials (Postgres password, Authentik `secret_key`,
  bootstrap admin password/token, Headlamp's OIDC client secret) are Tofu
  `random_password` resources, stored in this repo's state and as
  Kubernetes Secrets in the `cluster-auth` namespace , never hardcoded.
- The bootstrap API token (`AUTHENTIK_BOOTSTRAP_TOKEN`) is what the
  `authentik` provider authenticates with. It's tied to the initial
  `akadmin` account; if you rotate it, update `provider.tf`'s expectations
  accordingly.
- Wiring Headlamp itself to this OIDC provider happens in `cluster-config`.
