#!/usr/bin/env bash
set -euo pipefail

Redacted

export ECR_ACCOUNT_ID=$(env $infra_aws_creds aws sts get-caller-identity | jq -r '.Account')


function argocd_login() {
  export $infra_aws_creds
  aws eks update-kubeconfig --name "${MANAGEMENT_CLUSTER_NAME}"

  argo_cd_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

  echo "Connecting to Argo: ${argo_cd_url}"
  argocd login "${argo_cd_url}" --insecure --username admin --password "${argo_cd_password}" --grpc-web
  export $tgt_aws_creds
}


function argocd_delivery_service_account(){

  # Verify if creds already present in vault , Else generate and populate
  [ `vault kv get  || vault kv put ${} value="$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 16)"
  [ `vault kv get  ] && echo "Delivery CI username Already exists , skipping generation" || vault kv put ${} value="${}"




  argocd account update-password --account $argocd_ep_ea_appdev_service_user --new-password "${ARGOCD_EA_EP_APPDEV_PASSWORD}" --current-password "${argo_cd_password}"




function git_commit() {

  git config --global user.name "Concourse CI Bot"
  git config --global user.email "ci@localhost"

  cd "${cluster_resource_path}" || exit 1

  git add ./
  [[ ! $(git status --porcelain --untracked-files=no | wc -l) -gt 0 ]] || git commit -m "Updating Cluster Resource for ${CLUSTER_NAME} in ${AWS_DEFAULT_REGION}"

}

aws eks update-kubeconfig --name "${CLUSTER_NAME}" --alias "${CLUSTER_IDENTIFIER}"

if [ "${IDENTIFIER}" == "${MANAGEMENT_CLUSTER_IDENTIFIER}"  ]; then
  cluster_type="management"
else
  cluster_type="application"
fi

if [ "${OP}" = "install" ]; then

  if [ "${IDENTIFIER}" == "${MANAGEMENT_CLUSTER_IDENTIFIER}" ]; then

    echo "Applying argocd kustomization..."
    argocd_config_path="${task_root}/eks-bootstrap-repo/config/${IAAS}/argocd"
    cat "${argocd_config_path}/secret.template" | envsubst  > "${argocd_config_path}/argocd-github-ssh-secret.yml"
    kubectl apply -k ${argocd_config_path}

    echo "Management Cluster; Installing ArgoCD ..."
    echo "Bootstraping ArgoCD Cluster with Argo Autopilot"
    argocd-autopilot repo bootstrap --namespace argocd --app "${argocd_app_path}" --repo "${GIT_REPO}" --insecure --recover

  fi

  echo "Adding Cluster to ArgoCD ..."
  context=$(kubectl config current-context)

  argocd_login

  ECR_HOST="${ECR_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

  # Build the base argocd cluster add command
  cluster_add_cmd="argocd cluster add -y \
  --upsert \"${context}\" \
  --name \"${CLUSTER_IDENTIFIER}\" \
  --label cluster_name=\"${CLUSTER_NAME}\" \
  --label cluster_type=\"${cluster_type}\" \
  --label env_type=\"${ENV_TYPE}\" \
  --label cloud_provider=\"${IAAS}\" \
  --label cloud_region=\"${AWS_DEFAULT_REGION}\" \
  --label cloud_account_id=\"${CLOUD_ACCOUNT_ID}\" \
  --label ecr_host=\"${ECR_HOST}\" \
  --label cluster_dns_zone_name=\"${CLUSTER_DNS_ZONE_NAME}\""

  # Add fabric_env and region_id labels when TGT_IAM_ROLE is not empty (multi-account)
  if [[ -n $TGT_IAM_ROLE ]]; then
    cluster_add_cmd="${cluster_add_cmd} \
    --label fabric_env=\"${FABRIC_ENV}\" \
    --label region_id=\"${REGION_ID}\""
  fi

  # Execute the command
  eval "${cluster_add_cmd}"

  cluster_server=$(argocd cluster get "${CLUSTER_IDENTIFIER}" -o json | jq '.server' -r)

  cat <<-EOF > "${cluster_resource_path}/${CLUSTER_IDENTIFIER}.json"
	{"name":"$CLUSTER_IDENTIFIER","server":"$cluster_server"}
	EOF

  mkdir -p "${cluster_resource_path}/${CLUSTER_IDENTIFIER}"
	echo "# Cluster Resources" > "${cluster_resource_path}/${CLUSTER_IDENTIFIER}/README.md"
  git_commit

# If mangement cluster , then generate Service account for CI
  if [ "${IDENTIFIER}" == "${MANAGEMENT_CLUSTER_IDENTIFIER}" ]; then
Redacted
  fi

  argocd logout "${argo_cd_url}"

elif [ "${OP}" = "delete" ]; then
  context=$(kubectl config current-context)
  argocd_login

  if [ -n "$(argocd cluster list -o json | jq '.[].name'  | grep ${CLUSTER_IDENTIFIER})" ]; then
      echo "Marking cluster as disabled to cleanup resources"
      env $infra_aws_creds kubectl label secret --selector cluster_name="${CLUSTER_NAME}" --overwrite cluster_type=disabled -n argocd

      echo "Waiting for resource to be cleaned up..."
      sleep 300

      echo "Removing Cluster from ArgoCD ..."
      argocd cluster rm -y "${CLUSTER_IDENTIFIER}"
  else
      echo "Cluster doesn't exist in ArgoCD. Skipping ..."
  fi

  rm -f "${cluster_resource_path}/${CLUSTER_IDENTIFIER}.json"
  rm -rf "${cluster_resource_path}/${CLUSTER_IDENTIFIER}"
  git_commit

  argocd logout "${argo_cd_url}"

  if [ "${IDENTIFIER}" == "${MANAGEMENT_CLUSTER_IDENTIFIER}" ]; then

    echo "Removing ArgoCD from management cluster..."
    argocd-autopilot repo uninstall  --repo "${GIT_REPO}" --force
    kubectl delete namespace argocd

  fi

fi
