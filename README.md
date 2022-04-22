# RBC Kubernetes

This is a work in progress.

# Setup

## Required software

### argo cli

```bash
$ brew install argo
```

### kubeseal cli
```bash
$ brew install kubeseal
```

## Required k8s setup

### Repos

To install each repo, run the following commands:

**Note:** I've used sealed-secrets as an example. Replace repo name and uri with those from the list below.

```bash
$ helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
```

* Ingress Nginx
  * ingress-nginx
  * https://kubernetes.github.io/ingress-nginx
* Bitnami
  * bitnami
  * https://charts.bitnami.com/bitnami
* (Bitnami) Sealed Secrets
  * sealed-secrets
  * https://bitnami-labs.github.io/sealed-secrets

# Working locally

Use the following to review logs for your deployed pods:

```bash
# Review logs for your pods
$ kubectl logs deployment/rbc-api -n rbc-ecosystem

# Review logs for sealed secrets
# first get the generated pod name for sealed secrets controller
$ kubectl get pods -n rbc-ecosystem
# Then run logs
$ kubectl logs -f rbc-sealed-secrets-<generated_name> -n rbc-ecosystem

# Review logs for ingress
# first get the generated pod name for ingress controller
$ kubectl get pods
# Then run logs
$ kubectl logs rbc-nginx-ingress-<generated_name>
```

# CI/CD

## 1. Helm for YAML production

At the moment the below will output a single file with all chart YAML in it. See appendix for more info.

```bash
# From root
$ helm template rbc ./helm/rbc --skip-tests > ./kustomize/base/rbc.yaml
```

## 2. Kustomize for customisation and environment management



# Appendix

## Creating new secrets with Kubeseal

```bash
# 1. Deploy sealed secrets (SS) controller to k8s
# Note: most of the deploy will fail, but SS-c will work
$ skaffold dev
# 2. Create a new SS using kubeseal
# Note: to save a whole lot of hassle, we've set scope to be cluster-wide
$ kubectl \
    --namespace rbc-ecosystem \
    create secret generic rbc-api-super-secret \
    --dry-run=client \
    --from-literal username='jake_blues' \
    --from-literal password='jolietIsMyName' \
    --output yaml \
    | kubeseal \
    --scope cluster-wide \
    --controller-name=rbc-sealed-secrets \
    --format yaml > path-to-secret-file.yaml
```

## Helm for YAML production

The following outputs to multiple files, but it places them in a dir structure matching chart and dependency structure.

```bash
# From root
$ helm template rbc ./helm/rbc --skip-tests --output-dir ./base
```

It would be nicer if things were in separate files, but Helm doesn't offer anything in core or templates (apart from the above). The following includes a bash file example, but the comments RE risk of overwrite are 100% correct. Will look at this another day:

* https://github.com/helm/helm/issues/4680
