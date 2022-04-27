# RBC Kubernetes

This is for a personal project, so the README is largely geared towards myself (or future team members). If you find this useful, hooray, I hope I've kept the documentation generic enough you can make sense of it.

**Note:** I've tried to keep the key instructions brief, and to the point. Where decisions have been made, or further information is available I've (for now) moved it to the bottom in an Appendix. e.g. why there is mix of Helm & Kustomize is answered at the bottom rather than in situ. HTH.

# Setup - Software

*Apologies:* this is directed towards those on MacOS.

## argocd cli

```bash
$ brew install argocd
```

## Digital Ocean k8s cli
```bash
$ brew install doctl
```

## kubeseal cli
```bash
$ brew install kubeseal
```

## kustomize cli
```bash
$ brew install kustomize
```

# Setup K8s

## Repos

To install each repo, run the following commands:

**Note:** I've used sealed-secrets as an example. Replace repo name and uri with those from the list below.

```bash
$ helm repo add sealed-secrets https://bitnami-labs.github.io/sealed-secrets
```

* Argo
  * argo
  * https://argoproj.github.io/argo-helm
* (Bitnami) Sealed Secrets
  * sealed-secrets
  * https://bitnami-labs.github.io/sealed-secrets
* Ingress Nginx
  * ingress-nginx
  * https://kubernetes.github.io/ingress-nginx
* Bitnami
  * bitnami
  * https://charts.bitnami.com/bitnami
* Jetstack
  * jetstack
  * https://charts.jetstack.io

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

We use ArgoCD to deploy all of our applications to the cloud via GitOps, so there is no need for manual installation in the long term. To get yourself set up though, we need to take a few manual steps.

Some apps you'll need to install locally, I haven't bothered with ArgoCD for local K8s management as it seemed like overkill. You'll need to install the following locally:

- Ingress
- Sealed secrets

If you're using this as the basis for your own project, before anything will work in the cloud you'll need to install the following manually in your cloud cluster:

- Ingress
- Cert. manager
- ArgoCD

**Note:** we use custom wrapper charts around all of our third party apps to bundle `values.yaml` and any required custom templates. All of the installation instructions below use these wrapper charts rather than straight from the repository.

### Ingress

Already installed in cloud, so you just need to do your dev cluster. Based on the following article (for Digital Ocean), but adapted to use our local wrapper chart.

* https://github.com/digitalocean/Kubernetes-Starter-Kit-Developers/blob/main/03-setup-ingress-controller/nginx.md

**Recommended local settings**

Currently `values.yaml` is based on DO recommendation, `values-local.yaml` is more friendly to a local environment. Use the following commands to install [NGINX Ingress chart](https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx) locally. If you are installing into a cloud based cluster leave out the -f flag.

```bash
# Make sure you're in the correct context
$ kubectl config use-context <dev_context_name>
# Update dependencies
$ helm dep update infra/ingress-nginx
# Install ingress via our custom wrapper chart using recommended local settings
$ helm upgrade --install ingress-nginx infra/ingress-nginx  \
  --namespace ingress-nginx \
  --create-namespace \
  -f infra/ingress-nginx/values-local.yaml
# Check install was successful
$ kubectl get all -n ingress-nginx
$ helm ls -n ingress-nginx
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

### Cert manager (Cloud only)

Not currently installed in development. All core helm charts ignore TLS, it is added during CI/CD via Kustomize.

Installed in the cloud by following DO instructions:

- [#step-5---configuring-production-ready-tls-certificates-for-nginx](https://github.com/digitalocean/Kubernetes-Starter-Kit-Developers/blob/main/03-setup-ingress-controller/nginx.md#step-5---configuring-production-ready-tls-certificates-for-nginx)

```bash
# Make sure you're in the correct context
$ kubectl config use-context <cloud_context_name>
# Update dependencies
$ helm dep update infra/cert-manager
# Install ingress via our custom wrapper chart using recommended local settings
$ helm upgrade --install cert-manager infra/cert-manager  \
  --namespace cert-manager \
  --create-namespace
# Check install was successful
$ kubectl get all -n cert-manager
$ helm ls -n cert-manager
```

### Argo CD (Cloud only)

This one was tricky, but the result is stored in the values.yaml of our wrapper chart for ArgoCD. Some key points:

- `fullnameOverride` required
  - By including ArgoCD as dependency broke things like service endpoints
  - Using fullnameOverride reinstates the name Argo expects
- TLS/certificates
  - This was a real struggle
  - [Official docs for Ingress](https://argo-cd.readthedocs.io/en/stable/operator-manual/ingress/#kubernetesingress-nginx) (@ time of writing) included info that was marked as deprecated by [official TLS docs](https://argo-cd.readthedocs.io/en/stable/operator-manual/tls/)
  - Resolved via server.certificate.enabled and related parameters in the ArgoCD helm chart
  - *Note:* ArgoCD creates it's own certificate using this setup
  - Solution encapsulated within our wrapper chart

Install via:

```bash
# Make sure you're in the correct context
$ kubectl config use-context <cloud_context_name>
# Update dependencies
$ helm dep update infra/argo-cd
# Install ingress via our custom wrapper chart using recommended local settings
$ helm upgrade --install argo-cd infra/argo-cd  \
  --namespace argocd \
  --create-namespace
# Check install was successful
$ kubectl get all -n argocd
$ helm ls -n argocd
```

**Note:** namespace is without dash (`argocd`), while release name is with dash (`argo-cd`).

Configure your account to access ArgoCD:

```bash
# Get admin password stored in secret
$ export ARGO_PASS_OLD=$(kubectl -n argocd \
  get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" \
  | base64 -d)
# Login to ArgoCD CLI
$ argocd login \
  --username admin \
  --password $ARGO_PASS_OLD \
  --grpc-web \
  argocd.curiouscommunities.net
# Update the password to something different to the original
$ argocd account update-password \
  --current-password $ARGO_PASS_OLD \
  --new-password 'somethingSecure'
```

Add your projects and applications:

```bash
# Add projects for ArgoCD to track
$ kubectl apply -f git-ops/projects.yaml
# Add applications for ArgoCD to track
$ kubectl apply -f git-ops/apps.yaml
```

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

*Note:* where I have used `-n rbc-dev`, use the relevant namespace for the cluster you're working in e.g. `staging`, `production`, `your-namespace`

## Skaffold & Helm

For local development we use Skaffold, in related app repo, and the Helm version of our K8s configuration.

## Logging K8s

Use the following to review logs for your deployed pods:

```bash
# Review logs for your pods
$ kubectl logs deployment/rbc-api -n rbc-dev

# Review logs for sealed secrets
# first get the generated pod name for sealed secrets controller
$ kubectl get pods -n rbc-dev
# Then run logs
$ kubectl logs -f rbc-sealed-secrets-<generated_name> -n rbc-dev

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
$ kubectl get all -n rbc-dev

# Check on a specific thing
# kubectl describe <resource_name> <specific_resource_name> -n rbc-dev
$ kubectl describe pod rbc-api-55c76f6f7b-f769l -n rbc-dev
```

### Ingress issues

**Error obtaining Endpoints for Service**

Discovered by looking at ingress logs (see above). Then reviewing endpoints:

```bash
$ kubectl get endpoints -n <namespace>
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

## From Helm to Kustomize

Kustomize is better for multi-environment management. Our ArgoCD setup monitors the Kustomize directories for changes, not the Helm ones.

```bash
# Output helm charts as YAML
$ helm template rbc ./core/helm/rbc-api --skip-tests -n production > ./core/rbc-api/base/all.yaml
# Make any changes via Kustomize that you need to
# Test the kustomize output (even if you don't change Kustomize config)
# -o outputs to file
$ kustomize build core/rbc-api/overlays/production \
  -o k-test.yaml
```

## Commit and push

When you're happy, push to the main repo... TBC

TODO: mention in here that we build in the k8s cluster so that the container matches the k8s cluster architecture i.e. amd64 vs arm64.

# Appendix

## Notes on other supporting applications

### Argo Events

**The Helm chart [doesn't include the actual event bus](https://github.com/argoproj/argo-helm/issues/840)**

It may or may not in the future, we'll need to keep an eye on it. Until then, I've grabbed the default manifest from [Argo Events installation](https://argoproj.github.io/argo-events/installation/#using-helm-chart) guide and added it as a template.

**Setup steps for GitHub event source**

- https://argoproj.github.io/argo-events/eventsources/setup/github/

Most importantly create your own [personal access token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token) for GitHub. Give it all the permissions under the repo section, and then add it to a sealed secret:

```bash
# Create secret, and seal it using sealed-secrets
$ kubectl \
  --namespace argo-events \
  create secret generic github-access \
  --dry-run=client \
  --from-literal token='shhhImAToken' \
  --output yaml \
  | kubeseal \
  --controller-namespace=argocd \
  --controller-name=sealed-secrets \
  --format yaml > ./infra/argo-events/templates/github-access.yaml
```

### Argo Workflows

**Using ArgoCD for SSO**

Relevant docs:

- https://argoproj.github.io/argo-workflows/argo-server-sso-argocd/
- https://argoproj.github.io/argo-workflows/argo-server-sso/

They're not super helpful so, in summary:

*1. Create the following secret*

**Note:** Needs to exist in both namespaces.
**Note:** Do not use the values below, come up with your own values.

 ```bash
# Create one in argo namespace (for Workflows)
$ kubectl \
  --namespace argo \
  create secret generic argo-workflows-sso \
  --dry-run=client \
  --from-literal client-id='hT4cLvG6qwWqC7sbHzwf6kyz8' \
  --from-literal client-secret='txtUa9GEv7fAAqCmcFCfgmbd9g2ngbiU3fWNGQCN' \
  --output yaml \
  | kubeseal \
  --controller-namespace=argocd \
  --controller-name=sealed-secrets \
  --format yaml > ./infra/argo-workflows/templates/argo-workflows-sso.yaml
# The exact same secret, but in the argocd namespace and chart
$ kubectl \
  --namespace argocd \
  create secret generic argo-workflows-sso \
  --dry-run=client \
  --from-literal client-id='hT4cLvG6qwWqC7sbHzwf6kyz8' \
  --from-literal client-secret='txtUa9GEv7fAAqCmcFCfgmbd9g2ngbiU3fWNGQCN' \
  --output yaml \
  | kubeseal \
  --controller-namespace=argocd \
  --controller-name=sealed-secrets \
  --format yaml > ./infra/argo-cd/templates/argo-workflows-sso.yaml
```

*2. Update `values.yaml` [according to the docs](- https://argoproj.github.io/argo-workflows/argo-server-sso-argocd/)*

But double check the [default values.yaml](https://artifacthub.io/packages/helm/argo/argo-workflows) file from the artifact-hub. It indicates all values under server.sso need to be in place.

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

After much research (I wish I'd saved some bookmarks), I've found (as usual) there are many strong opinions touting one over the other, but also more than a few promoting the value of using both. They are both wonderful tools that have a place; sometimes one outdoes the other for particular scenarios so why not employ them for that purpose.

The over-arching goal is to keep complexity down, so I hope I have managed that (guided by other people's experiences).

### Update: 2022-04-25

In the end I've gone with Helm more broadly, with Kustomize for environment management mostly.

## Creating new secrets with Kubeseal

**Important note:** you need to create the sealed secret using the sealed secret controller that is going to unseal it. SO for sealed secrets that will be unsealed in the cloud, you need to use the cloud cluster context to run kubeseal (so it uses the cloud based ss-controller).

```bash
# 1. Deploy sealed secrets (SS) controller to k8s
# Note: most of the deploy will fail, but SS-c will work
$ skaffold dev
# 2. Create a new SS using kubeseal
# Note: to save a whole lot of hassle, we've set scope to be cluster-wide
$ kubectl \
  --namespace rbc-dev \
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
  --namespace rbc-dev \
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
$ helm template rbc ./core/helm/rbc --skip-tests  -n production --output-dir ./base
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

## Other useful software

### Stern

For multi-pod/multi-anything log tailing:

- https://theiconic.tech/tail-logs-from-multiple-kubernetes-pods-the-easy-way-71401b84d7f
- https://github.com/stern/stern

Let's you do things like:

```bash
# See what's happening with your ingress
$ stern -n ingress-nginx ingress-nginx-controller

```
