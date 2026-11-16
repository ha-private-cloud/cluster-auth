# cluster-auth

Who can get into the Talos cluster. People sign in to Headlamp and the Kubernetes API with their ClusterKeep account from auth-api, and this repo decides what each group can do. It used to install Authentik, which has been retired.

## What it creates

- A ClusterRoleBinding for each cluster group in auth-api:

  | auth-api group | Kubernetes role |
  |---|---|
  | `cluster-admins` | `cluster-admin` |
  | `cluster-editors` | `edit` |
  | `cluster-viewers` | `view` |

- Headlamp's client secret, written into the `cluster-identity` Secret in auth-api's production namespace. auth-api registers Headlamp with it when it starts, and this repo restarts auth-api whenever the secret changes.
- Headlamp's client settings as outputs, which `cluster-config` reads when it installs Headlamp.

The Kubernetes API only trusts auth-api once the Talos patch in `proxmox-tofu` is applied to every control plane. Group names reach Kubernetes with an `oidc:` prefix, set by `oidc_groups_prefix`, and that prefix must match the patch. Without it, auth-api could hand someone a built-in group such as `system:masters`.

## Giving someone access

Use the Cluster access setting in admin-ui. Only members of `cluster-admins` can change it, and nobody can change their own. The bootstrap `admin` account in auth-api is a cluster admin, so there's always a way back in.

## Using it

All the OpenTofu files are in `tofu/`, and the tfvars on the CI bastion only need the kubeconfig path. Pushing a `vX.Y.Z` tag plans the change through the shared `pipelines` workflow, and applying it is a manual run of that workflow. Apply this before `cluster-config`, because Headlamp's settings come from here.
