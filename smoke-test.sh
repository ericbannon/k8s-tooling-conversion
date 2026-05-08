#!/usr/bin/env bash
set -uo pipefail

echo "=== Binary checks ==="

required_bins=(
  bash
  aws
  jq
  kubectl
  argocd
  vault
  git
  envsubst
  base64
  tr
  head
  grep
  wc
  sleep
  yq
  ytt
  kapp
  eksctl
  kustomize
  helm
  terraform
  terragrunt
  istioctl
  pack
  op
  credhub
)

missing=0

for bin in "${required_bins[@]}"; do
  if command -v "$bin" >/dev/null 2>&1; then
    echo "FOUND:   $bin -> $(command -v "$bin")"
  else
    echo "MISSING: $bin"
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  echo "Smoke test failed: missing required binaries."
  exit 1
fi

set -e

echo
echo "=== Version checks ==="

aws --version
kubectl version --client=true
argocd version --client
argocd-autopilot version || true
vault version
git --version
jq --version
helm version --short
terraform version
istioctl version --remote=false || true
pack version
op --version
credhub --version || true
kubergrunt --version || true
eksctl version
kustomize version
kapp version
ytt version
yq --version
terragrunt --version

echo
echo "=== Functional checks ==="

test "$(echo 'hello ${NAME}' | NAME=world envsubst)" = "hello world"
echo "PASS: envsubst"

test "$(echo '{"x":1}' | jq -r '.x')" = "1"
echo "PASS: jq"

cat <<YAML >/tmp/test.yaml
a:
  b: 1
YAML

test "$(yq '.a.b' /tmp/test.yaml)" = "1"
echo "PASS: yq"

mkdir -p ~/.kube
touch ~/.kube/config
kubectl config get-contexts >/dev/null || true
echo "PASS: kubectl config"

git config --global user.name "test"
git config --global user.email "test@test.com"
echo "PASS: git config"

echo
echo "=== Terraform provider checks ==="

if [ -d /usr/local/share/smoke/terraform-provider-smoke ]; then
  tf_smoke_dir="$(mktemp -d)"
  cp -R /usr/local/share/smoke/terraform-provider-smoke/. "${tf_smoke_dir}/"

  terraform -chdir="${tf_smoke_dir}" init -backend=false
  rm -rf "${tf_smoke_dir}"

  echo "PASS: terraform providers init"
else
  echo "SKIP: terraform provider smoke files not found"
fi

echo
echo "=== Smoke test passed ==="
