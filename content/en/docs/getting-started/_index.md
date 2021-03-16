---
title: "Getting Started"
linkTitle: "Getting Started"
weight: 1
description: >
  Install OLM in a kubernetes cluster.
---

## Prerequisites

- [git](https://git-scm.com/downloads)
- [go](https://golang.org/dl/) version `v1.12+`.
- [docker](https://docs.docker.com/install/) version `17.03`+ or [podman](https://github.com/containers/libpod/blob/master/install.md) `v1.2.0+` or [buildah](https://github.com/containers/buildah/blob/master/install.md) `v1.7+`.
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) `v1.11.3+`.
- Access to a Kubernetes `v1.11.3+` cluster.

## Installing OLM in your cluster

### Install Released OLM

For installing release versions of OLM, for example version 0.15.1, you can use the following command:

```sh
export olm_release=0.15.1
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${olm_release}/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${olm_release}/olm.yaml
```

Learn more about available releases [here](https://github.com/operator-framework/operator-lifecycle-manager/releases).

To deploy OLM locally on a [minikube cluster](https://kubernetes.io/docs/tasks/tools/install-minikube/) for development work, use the `run-local` target in the [Makefile](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Makefile).

```sh
git clone https://github.com/operator-framework/operator-lifecycle-manager.git
cd operator-lifecycle-manager
make run-local
```

### Verify Installation

You can verify your installation of OLM by first checking for all the necessary CRDs in the cluster:

```sh
$ kubectl get crd
NAME                                          CREATED AT
catalogsources.operators.coreos.com           2019-10-21T18:15:27Z
clusterserviceversions.operators.coreos.com   2019-10-21T18:15:27Z
installplans.operators.coreos.com             2019-10-21T18:15:27Z
operatorgroups.operators.coreos.com           2019-10-21T18:15:27Z
subscriptions.operators.coreos.com            2019-10-21T18:15:27Z
```

And then inspecting the deployments of OLM and it's related components:

```sh
$ kubectl get deploy -n olm
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
catalog-operator   1/1     1            1           5m52s
olm-operator       1/1     1            1           5m52s
packageserver      2/2     2            2           5m43s
```

## Installing OLM with Operator SDK

The [`operator-sdk`][operator-sdk] provides a command to easily install and uninstall OLM for developmental purposes. See the [SDK installation guide][sdk-installation-guide] on how to install `operator-sdk` tooling.

With `operator-sdk` installed, you can easily install OLM on your cluster by running `operator-sdk olm install`. It is just as easy to uninstall OLM by running `operator-sdk uninstall olm`.  For more information about how to integrate your project using [`operator-sdk`][operator-sdk] CLI tool, see the following [OLM integration][sdk-olm-integration] section.

## Installing an operator bundle with Operator SDK

You can use the [`operator-sdk`][operator-sdk] CLI to run your bundle with [`operator-sdk run bundle`][cli-run-bundle].

Given a bundle image is present in a registry, [`operator-sdk run bundle`][cli-run-bundle] can create a pod to serve that bundle to OLM via a [`Subscription`][install-your-operator], along with other OLM objects, ephemerally. Following an example:

```console
$ operator-sdk run bundle <some-registry>/memcached-operator-bundle:v0.0.1
INFO[0008] Successfully created registry pod: <some-registry>-memcached-operator-bundle-0-0-1
INFO[0008] Created CatalogSource: memcached-operator-catalog
INFO[0008] OperatorGroup "operator-sdk-og" created
INFO[0008] Created Subscription: memcached-operator-v0-0-1-sub
INFO[0019] Approved InstallPlan install-krv7q for the Subscription: memcached-operator-v0-0-1-sub
INFO[0019] Waiting for ClusterServiceVersion "default/memcached-operator.v0.0.1" to reach 'Succeeded' phase
INFO[0019]   Waiting for ClusterServiceVersion "default/memcached-operator.v0.0.1" to appear
INFO[0031]   Found ClusterServiceVersion "default/memcached-operator.v0.0.1" phase: Pending
INFO[0032]   Found ClusterServiceVersion "default/memcached-operator.v0.0.1" phase: Installing
INFO[0040]   Found ClusterServiceVersion "default/memcached-operator.v0.0.1" phase: Succeeded
INFO[0040] OLM has successfully installed "memcached-operator.v0.0.1"
```

**Note** For more information about how to integrate your project using [`operator-sdk`][operator-sdk] CLI tool, see the following [OLM integration][sdk-olm-integration] section.

## Running OLM locally with minikube 

This command starts minikube, builds the OLM containers locally with the minikube-provided docker, and uses the local configuration in [local-values.yaml][local-values.yaml] to build localized deployment resources for OLM.

```bash
# To install and run locally
make run-local
```

You can verify that the OLM components have been successfully deployed by running `kubectl -n local get deployments`.

## User Interface (Running the Console Locally)

To interact with OLM and its resources via a web browser, you can use the [web-console][web-console] in a Kubernetes cluster.

```bash 
git clone https://github.com/openshift/origin-web-console
cd origin-web-console
make run-console-local
```

You can then visit `http://localhost:9000` to view the console. 

## Customizing OLM installations 

Deployments of OLM can be stamped out with different configurations by writing a `values.yaml` file and running commands to generate resources.

Here's an example `values.yaml`:

```yaml
# sets the apiversion to use for rbac-resources. Change to `authorization.openshift.io` for openshift
rbacApiVersion: rbac.authorization.k8s.io
# namespace is the namespace the operators will _run_
namespace: olm
# watchedNamespaces is a comma-separated list of namespaces the operators will _watch_ for OLM resources.
# Omit to enable OLM in all namespaces
watchedNamespaces: olm
# catalog_namespace is the namespace where the catalog operator will look for global catalogs.
# entries in global catalogs can be resolved in any watched namespace
catalog_namespace: olm
# operator_namespace is the namespace where the operator runs
operator_namespace: operators
# OLM operator run configuration
olm:
  # OLM operator doesn't do any leader election (yet), set to 1
  replicaCount: 1
  # The image to run. If not building a local image, use sha256 image references
  image:
    ref: quay.io/operator-framework/olm:local
    pullPolicy: IfNotPresent
  service:
    # port for readiness/liveness probes
    internalPort: 8080
# catalog operator run configuration
catalog:
  # Catalog operator doesn't do any leader election (yet), set to 1
  replicaCount: 1
  # The image to run. If not building a local image, use sha256 image references
  image:
    ref: quay.io/operator-framework/olm:local
    pullPolicy: IfNotPresent
  service:
    # port for readiness/liveness probes
    internalPort: 8080
```

To configure a release of OLM for installation in a cluster:

1. Create a `my-values.yaml` like the example above with the desired configuration or choose an existing one from this repository. The latest production values can be found in [deploy/upstream/values.yaml][deploy-upstream-values].

1. Generate deployment files from the templates and the `my-values.yaml` using `package_release.sh`

   ```bash
   # first arg must be a semver-compatible version string
   # second arg is the output directory
   # third arg is the values.yaml file
   ./scripts/package_release.sh 1.0.0-myolm ./my-olm-deployment my-values.yaml
   ```

1. Deploy to kubernetes: `kubectl apply -f ./my-olm-deployment/templates/`

The above steps are automated for official releases with `make ver=0.3.0 release`, which will output new versions of manifests in `deploy/tectonic-alm-operator/manifests/$(ver)`.

## Overriding the Global Catalog Namespace

It is possible to override the Global Catalog Namespace by setting the `GLOBAL_CATALOG_NAMESPACE` environment variable in the catalog operator deployment.

## Subscribe to a Package and Channel

Cloud Services can be installed from the catalog by subscribing to a channel in the corresponding package.

If using one of the `local` run options, this will subscribe to `etcd`, `vault`, and `prometheus` operators. Subscribing to a service that doesn't exist yet will install the operator and related CRDs in the namespace.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: etcd
  namespace: olm
spec:
  channel: singlenamespace-alpha
  name: etcd
  source: operatorhubio-catalog
  sourceNamespace: olm
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: prometheus
  namespace: olm
spec:
  channel: alpha
  name: prometheus
  source: operatorhubio-catalog
  sourceNamespace: olm
```

To learn more about packaging your operator for OLM, installing/uninstalling an operator etc, visit the [Core Tasks](/docs/tasks/) and the [Advanced Tasks](/docs/advanced-tasks/) section of this site.


[operator-sdk]: https://github.com/operator-framework/operator-sdk
[sdk-installation-guide]: https://sdk.operatorframework.io/docs/installation/
[sdk-olm-integration]: https://sdk.operatorframework.io/docs/olm-integration/
[deploy-upstream-values]: https://github.com/operator-framework/operator-lifecycle-manager/blob/0.16.1/deploy/upstream/values.yaml
[local-values.yaml]: https://github.com/operator-framework/operator-lifecycle-manager/blob/0.16.1/doc/install/local-values.yaml
[cli-run-bundle]: https://sdk.operatorframework.io/docs/cli/operator-sdk_run_bundle/
[install-your-operator]: /docs/tasks/install-operator-with-olm/#install-your-operator
[web-console]: https://github.com/openshift/origin-web-console
