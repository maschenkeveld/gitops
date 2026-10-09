# gitops

Flux CD GitOps examples for Kong on Kubernetes. This is a trimmed, shareable copy of a personal
home-lab repo: environment-specific values (domains, secret stores, IDs, tokens) are replaced with
placeholders. Search for `example.com`, `REPLACE_WITH_` and `you@example.com` and substitute your own.

## Companion repositories

| Repository | Role |
|---|---|
| [konnect-eu-ko-dp-shared-2](https://github.com/maschenkeveld/konnect-eu-ko-dp-shared-2) / [-3](https://github.com/maschenkeveld/konnect-eu-ko-dp-shared-3) | Terraform: creates the Konnect control planes the Kong Operator mirrors |
| [konnect-eu-apiops-development](https://github.com/maschenkeveld/konnect-eu-apiops-development) | Terraform: control plane + Developer Portal |
| [apiops](https://github.com/maschenkeveld/apiops) | CI/CD: deck + kongctl pipeline that deploys APIs and publishes them to the portal |

## Layout

- `clusters/<cluster>/` - one directory per cluster Flux is bootstrapped on. `flux-system/` is the
  generated Flux bootstrap; every other file is one or more Flux `Kustomization`s pointing at a component.
  - `shared-pve-1` - Kong Operator, cert-manager, external-dns, external-secrets
  - `mink-zone-a-pve-1`, `mink-zone-b-pve-1` - Kong Mesh zones with a Konnect data plane and demo workloads
- `<component>/` - reusable Kustomize manifests (`base/prerequisites`, `base/deployment`, `base/configs`,
  and optional per-cluster overrides under `clusters/`).

## Kong Operator

`kong-operator/` installs the operator (Helm) and configures Konnect-backed data planes. Flux applies it
in order: `prerequisites` -> `deployment` -> `auth-secret` -> `auth-configs` -> `configs`.

How the pieces connect:

1. Terraform (`konnect-eu-ko-dp-shared-2` / `-3`) creates a Konnect control plane and writes its
   connection details to OpenBao.
2. External Secrets Operator reads the Konnect API token (and certificates) from OpenBao via the
   `openbao` `ClusterSecretStore` (`external-secrets/base/configs`).
3. `kong-operator/clusters/shared/configs/kgw-cp-shared-N.yaml` references the Terraform-created control
   plane in **Mirror** mode, by ID - set `id:` to the `control_plane_id` Terraform output.
4. `KonnectExtension` + `DataPlane` (`konnect-extension-shared-N.yaml`, `dp-shared-N.yaml`) deploy the data
   plane and connect it to Konnect using the client certificate in `dp-tls-shared-N.yaml`.

The Konnect token is never stored in git: it is injected at build time by Flux `postBuild.substituteFrom`
from a Secret created by an `ExternalSecret`.

## Before you use it

- Point `ClusterSecretStore` at your own OpenBao/Vault, or swap in another secret backend.
- Replace the placeholder domain, e-mail and Cloudflare token (`external-dns`, `cert-manager`).
- Bootstrap Flux yourself so the deploy key/secret is created in your cluster
  (`flux bootstrap github --owner <you> --repository gitops --path clusters/<cluster>`).
