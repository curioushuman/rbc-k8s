# RBC Kubernetes

This is for a personal project, so the README is largely geared towards myself (or future team members). If you find this useful, hooray, I hope I've kept the documentation generic enough you can make sense of it.

**Note:** I've tried to keep the key instructions brief, and to the point. Where decisions have been made, or further information is available I've (for now) moved it to the bottom in an Appendix. e.g. why there is mix of Helm & Kustomize is answered at the bottom rather than in situ. HTH.

# Setup - Software

*Apologies:* this is directed towards those on MacOS.

## Digital Ocean k8s cli
```bash
$ brew install doctl
```

## argo cli

```bash
$ brew install argo
```

## kubeseal cli
```bash
$ brew install kubeseal
```

# Setup K8s

## Repos

To install each repo, run the following commands:

**Note:** I've used sealed-secrets as an example. Replace repo name and uri with those from the list below.

```bash
$ helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
```

* (Bitnami) Sealed Secrets
  * sealed-secrets
  * https://bitnami-labs.github.io/sealed-secrets
* Ingress Nginx
  * ingress-nginx
  * https://kubernetes.github.io/ingress-nginx
* Bitnami
  * bitnami
  * https://charts.bitnami.com/bitnami

## Clusters

### Create development cluster

Currently I'm using Docker Desktop. Use what you like.


### Connect to cloud cluster

Currently I'm using Digital Ocean (DO), I'll assume I've given you access. Use the following article to connect:

* https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/

This will result in a k8s context that will allow kubectl (and related) to engage with your cloud cluster.

```bash
# Check your contexts, you should have dev and now cloud
$ kubectl config get-contexts
# Check which context you're in
$ kubectl config current-context
# Switch between contexts using
# kubectl config use-context <context_name>
$ kubectl config use-context docker-desktop
```

## Manually install (some) applications

We use ArgoCD to manage all of our applications in the cloud, but to get things to work locally (using Skaffold) we need to install some manually:

- Ingress
- Sealed secrets

**Note:** we use custom wrapper charts around all of our third party apps to bundle `values.yaml` and any required custom templates.

### Ingress

Already installed in cloud, so you just need to do your dev cluster. Based on the following article (for Digital Ocean), but adapted to use our local wrapper chart.

* https://github.com/digitalocean/Kubernetes-Starter-Kit-Developers/blob/main/03-setup-ingress-controller/nginx.md

**Recommended local settings**

Currently `values.yaml` is based on DO recommendation, `values-local.yaml` is more friendly to a local environment. Use the following commands to install [NGINX Ingress chart](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx) locally. If you are installing into a cloud based cluster leave out the -f flag.

```bash
# Make sure you're in the correct context
$ kubectl config use-context <dev_context_name>
# Update dependencies
$ helm dep update infra/ingress
# Install ingress via our custom wrapper chart using recommended local settings
$ helm upgrade --install ingress-nginx infra/ingress-nginx  \
  --namespace ingress-nginx \
  --create-namespace \
  -f infra/ingress-nginx/values-local.yaml
# Check install was successful
$ kubectl get all -n ingress-nginx
```

### Sealed secrets

Installation in cloud will be managed by ArgoCD, but you'll need this locally for the core applications to function. We install in the `argocd` namespace both locally and in the cloud.

```bash
# Make sure you're in the correct context
$ kubectl config use-context <dev_context_name>
# Update dependencies
$ helm dep update infra/sealed-secrets
# Install ingress via our custom wrapper chart using recommended local settings
$ helm upgrade --install sealed-secrets infra/sealed-secrets  \
  --namespace argocd \
  --create-namespace \
  -f infra/sealed-secrets/values-local.yaml
# Check install was successful
$ kubectl get all -n argocd
```

### Argo CD (Cloud only)

Not required locally, only in the cloud. Manual install via helm is required before it can manage all of our applications, but this should have already been taken care of.

# Setup - other

## Configure local domain

Local k8s configuration uses *rbc.dev* in it's configurations. You'll need to tell your computer that this points at *localhost*.

```bash
# Edit your hosts file
$ sudo vim /etc/hosts
# Add the following line (without the #)
# 127.0.0.1 rbc.dev
```

# Development

## Logging K8s

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

## Troubleshooting K8s

### Lens is super useful

A nice GUI to review status of your various clusters:

* Download [Lens IDE](https://k8slens.dev/desktop.html)

### Useful kubectl commands

The following commands can be quite useful to troubleshoot:

```bash
# Check on all the things
$ kubectl get all -n rbc-ecosystem

# Check on a specific thing
# kubectl describe <resource_name> <specific_resource_name> -n rbc-ecosystem
$ kubectl describe pod rbc-api-55c76f6f7b-f769l -n rbc-ecosystem
```

### Annoying situations to be aware of

- Ingress load balancer service stuck in pending
  - Restart docker for desktop to fix this
  - https://github.com/kubernetes/ingress-nginx/issues/7686#issuecomment-991761784

## Updating configuration for third party apps

If we need to make changes to any of the third party app configuration we need to first test these changes locally, then in staging (when such a thing is made possible), before we move them into production. Update the relevant `<chart>/values-local.yaml` and upgrade locally using the following commands; using ingress as an example:

```bash
# Make sure you're in the correct context
$ kubectl config use-context <dev_context_name>
# Update dependencies
$ helm dep update infra/ingress
# Update ingress with custom settings for local
$ helm upgrade ingress-nginx infra/ingress-nginx  \
  --namespace ingress-nginx \
  -f infra/ingress-nginx/values-local.yaml
```

Make sure everything works, and then:

- Copy these changes over to `values.yaml` (if not already present)
- Use CI (below) to promote changes to staging environment

# CI/CD

TBC

# Appendix

## Decision: moving away from Umbrella Helm chart

As I moved into using ArgoCD for CI/CD I realised that it would be better for the core project charts to be considered separate entities so ArgoCD could monitor, and update, separately.

## Why manual steps in k8s setup?

During my journey I think I was holding on too tightly to the "automate everything" and "declarative for all" mantras. While these are both important, and still my goals, I need to remember there will be some times when we're playing around with the k8s setup and doing things manually is perfectly acceptable (until the correct configuration is hit upon).

So, we have the following approach for non-core apps:

- Those required in dev and cloud
  - Configuration stored declaratively
  - Install manually into local cluster
    - Supported by instructions in README
  - Update manually where necessary
  - Save updates to declarative configuration
- Those only required in cloud
  - Configuration defined declaratively
  - Install/update managed by ArgoCD

## Organisation of charts/manifests

### core

i.e. what we're here to work on, the project itself.

### git-ops

This is where we keep our Argo configuration i.e. projects, apps, etc.

### infra

Everything else that is required:

- To get the project FROM development TO production
- AND keep it there

Examples include:

- The full Argo suite; CD, Events, Workflows
- Ingress configuration
- Prometheus & Grafana

## Why Helm AND Kustomize?

After much research (I wish I'd saved some bookmarks), I've found (as usual) there are many strong opinions touting one over the other, but als more than a few promoting the value of using both. They are both wonderful tools that have a place; sometimes one outdoes the other for particular scenarios so why not employ them for that purpose.

The over-arching goal is to keep complexity down, so I hope I have managed that (guided by other people's experiences).

### Update: 2022-04-25

In the end I've gone with Helm more broadly, and I may come back to adding Kustomize in as and when it is required.

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
  --controller-namespace=argocd \
  --controller-name=sealed-secrets \
  --format yaml > path-to-secret-file.yaml

# MongoDb specific secret requirements
$ kubectl \
  --namespace rbc-ecosystem \
  create secret generic rbc-api-mongodb \
  --dry-run=client \
  --from-literal mongodb-passwords='pa$$word' \
  --from-literal mongodb-root-password='r00tPa$$word' \
  --from-literal mongodb-replica-set-key='somethingLongBase64' \
  --output yaml \
  | kubeseal \
  --controller-namespace=argocd \
  --controller-name=sealed-secrets \
  --format yaml > rbc-api-access-mongodb.yaml
# Then you'll need to copy the contents of output into the relevant file
```

## Can Helm output multiple YAML files?

Yes, but no. The following outputs to multiple files, but it places them in a dir structure matching chart and dependency structure.

```bash
# From root
$ helm template rbc ./core/helm/rbc --skip-tests --output-dir ./base
```

It would be nicer if things were in separate files, but Helm doesn't offer anything in core or plugins (apart from the above). The following includes a bash file example, but the comments RE risk of file overwrite are 100% correct. Will look at this another day:

* https://github.com/helm/helm/issues/4680

### Update: 2022-04-25

This is vastly improved now I've moved everything out of the Hlm umbrella chart. However, there is still the risk of file overwriting where any dependency is included so do be careful.

## Inspiration

Approach heavily influenced by the following

### DevOps Toolkit

* https://www.youtube.com/watch?v=XNXJtxkUKeY

Amazing set of videos. The link above is to the combined one, but it includes links to all the individual ones which are an absolute MUST before trying to put it all together.

### Arthur Koziel

* https://github.com/arthurk/argocd-example-install

I found this article and repo super helpful when considering how I would structure my project, and properly employ helm.
