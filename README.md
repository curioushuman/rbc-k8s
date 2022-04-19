# RBC Kubernetes

This is a work in progress.

# Setup

## Required software

### argo cli

```zsh
$ brew install argo
```

### kubeseal cli
```zsh
$ brew install kubeseal
```

## Required k8s setup

### Create namespace

```zsh
$ kubectl create ns rbc
```

### Repos

To install each repo, run the following commands:

**Note:** I've used sealed-secrets as an example. Replace repo name and uri with those from the list below.

```zsh
$ helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
```

* Bitnami
  * bitnami
  * https://charts.bitnami.com/bitnami
* (Bitnami) Sealed Secrets
  * sealed-secrets
  * https://bitnami-labs.github.io/sealed-secrets

# CI/CD

## 1. Helm for YAML production

At the moment the below will output a single file with all chart YAML in it. See appendix for more info.

```zsh
# From root
$ helm template rbc rbc --skip-tests > ./base/rbc.yaml
```

## 2. Kustomize for customisation and environment management



# Appendix

## Helm for YAML production

The following outputs to multiple files, but it places them in a dir structure matching chart and dependency structure.

```zsh
# From root
$ helm template rbc rbc --skip-tests --output-dir ./base
```

It would be nicer if things were in separate files, but Helm doesn't offer anything in core or templates (apart from the above). The following includes a bash file example, but the comments RE risk of overwrite are 100% correct. Will look at this another day:

* https://github.com/helm/helm/issues/4680
