Script changes FROM ``` argocd-autopilot repo bootstrap ```

TO

```
terraform -chdir="${task_root}/terraform/argocd-bootstrap" init
terraform -chdir="${task_root}/terraform/argocd-bootstrap" apply -auto-approve \
  -var="git_repo=${GIT_REPO}" \
  -var="argocd_app_path=${argocd_app_path}"
```

Instead of baking these into the image:

```
root-app.yaml
argocd-values.yaml
applications/
bootstrap/
```

Keep in git:

i.e.

```
gitops-repo/
  bootstrap/
    root-app.yaml
    argocd-values.yaml
```

Then Terraform references 

```
manifest = yamldecode(file("${path.module}/bootstrap/root-app.yaml"))
```
