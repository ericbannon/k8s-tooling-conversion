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

Then Terraform references 

```
manifest = yamldecode(file("${path.module}/bootstrap/root-app.yaml"))
```
