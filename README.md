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


