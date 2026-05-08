# K8s Tooling Image (Chainguard FIPS Conversion)

## Overview

This image is a hardened Kubernetes/GitOps tooling image migrated from a traditional Alpine + wget-based Dockerfile to a Chainguard FIPS-based multi-stage build.

The primary goals of this conversion were:

* Reduce CVE surface area
* Replace manually downloaded binaries with Chainguard images/APKs where possible
* Improve provenance and supply chain security
* Simplify maintenance/upgrades
* Enable FIPS-compliant runtime tooling
* Reduce embedded dependency drift

The image now primarily composes tooling from:

* Chainguard FIPS images
* Wolfi/APK packages
* Minimal remaining upstream binaries where no APK/image exists

## Chainguard Image-Based Tools

These are sourced directly from Chainguard hardened images:

* kubectl
* terraform
* terragrunt
* helm
* argocd
* argo
* vault
* aws-cli

## CVE-Guarded APK-Based Tools

Installed via Wolfi/APK repositories:

* bash
* jq
* yq
* ytt
* kapp
* eksctl
* kustomize
* istioctl
* git
* curl
* gettext/envsubst
* openssh-client
* buildkit
* coreutils
* wget
* zip

## Remaining Upstream Binaries

These currently do not have suitable APKs/images available:

* op (1Password CLI)
* credhub
* pack (Cloud Native Buildpacks CLI)

These are fetched during build in a dedicated fetch stage.

## Security Improvements

Removed Components:

The following tooling was removed or made optional to reduce CVE footprint:

* kubergrunt
* argocd-autopilot
* embedded Terraform provider caches
* legacy manually-downloaded binaries

# ArgoCD Bootstrap Modernization

Previous Approach (Autopilot)

The original implementation used:

```
argocd-autopilot repo bootstrap
```
to:

* install ArgoCD
* create bootstrap Applications
* configure GitOps repositories
* initialize regional management clusters

While functional, this introduced:

* additional embedded dependencies
* higher CVE surface area
* another upstream lifecycle to manage

## Terraform-Based Replacement

An alternative approach is now documented using:

* Terraform Helm provider
* Terraform Kubernetes provider
* kubectl_manifest resources

This removes the dependency on argocd-autopilot entirely. See the README in Terraform for examples

**GitOps State Location**

* root-app.yaml
* ArgoCD Applications
* AppProjects
* Helm values
* bootstrap manifests

# Build

```
docker build -f dockerfile.cg -t k8s-tooling:latest .
```

# Smoke Testing
The image includes a smoke test script:
```
smoke-test.sh
```
which validates:

* required binaries
* versions
* basic CLI functionality
* Terraform provider initialization

```
docker run --rm k8s-tooling:latest smoke-test.sh
```

# FIPS Validation
```
docker run --rm --privileged k8s-tooling:latest fips-test.sh
```
The following components are validated as part of the FIPS crypto path:

* OpenSSL 3.x
* Chainguard OpenSSL FIPS Provider
* Chainguard FIPS images
* TLS enforcement behavior
* approved-only crypto mode
* blocked non-approved algorithms

**NOTE: The following helper binaries are included for operational workflows outside of the crypto boundary**

* op
* credhub
* pack

These are:

* statically linked upstream binaries
* operational tooling only
* outside the validated OpenSSL FIPS module boundary

Auditors accept which binaries are inside the validated crypto boundary, and which are merely operational utilities. Acceptable risk statement would be:

O"perational helper binaries are outside the validated cryptographic module boundary and are not relied upon for FIPS-validated cryptographic operations."

## PO&AM Documentation

### 1Password CLI

Track the latest 1Password CLI (`op`) releases and changelog here:

- https://app-updates.agilebits.com/product_history/CLI2

op-cli 2.34.0 embeds go1.25.7 in the latest release and upstream must release a that include Go 1.25.9+ in order to resolve these upstream. Cannot be fixed by organization



