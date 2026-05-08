Script changes FROM ``` argocd-autopilot repo bootstrap ```

TO

```
terraform -chdir="${task_root}/terraform/argocd-bootstrap" init
terraform -chdir="${task_root}/terraform/argocd-bootstrap" apply -auto-approve \
  -var="git_repo=${GIT_REPO}" \
  -var="argocd_app_path=${argocd_app_path}"
```
