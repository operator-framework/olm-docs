---
title: "QuickStart"
linkTitle: "QuickStart"
weight: 1
description: >
  Install OLM in a kubernetes cluster, then install an operator using OLM.
---

## Prerequisites

- Access to a Kubernetes `v1.11.3+` cluster.
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) `v1.11.3+`.

## Installing OLM in your cluster

The `operator-sdk` binary provides a command to easily install and uninstall OLM in a Kubernetes cluster. See the [SDK installation guide][sdk-installation-guide] on how to install `operator-sdk` tooling.

After you have the `operator-sdk` binary installed, you can install OLM on your cluster by running `operator-sdk olm install`.

```bash
$ operator-sdk olm install
INFO[0000] Fetching CRDs for version "latest"
INFO[0000] Fetching resources for resolved version "latest"
I0302 14:26:13.947244   61268 request.go:682] Waited for 1.041225333s due to client-side throttling, not priority and fairness, request: GET:https://127.0.0.1:63693/apis/flowcontrol.apiserver.k8s.io/v1beta2?timeout=32s
INFO[0006] Creating CRDs and resources
INFO[0006]   Creating CustomResourceDefinition "catalogsources.operators.coreos.com"
INFO[0006]   Creating CustomResourceDefinition "clusterserviceversions.operators.coreos.com"
INFO[0006]   Creating CustomResourceDefinition "installplans.operators.coreos.com"
INFO[0006]   Creating CustomResourceDefinition "olmconfigs.operators.coreos.com"
INFO[0006]   Creating CustomResourceDefinition "operatorconditions.operators.coreos.com"
INFO[0006]   Creating CustomResourceDefinition "operatorgroups.operators.coreos.com"
INFO[0006]   Creating CustomResourceDefinition "operators.operators.coreos.com"
INFO[0006]   Creating CustomResourceDefinition "subscriptions.operators.coreos.com"
INFO[0006]   Creating Namespace "olm"
INFO[0006]   Creating Namespace "operators"
INFO[0006]   Creating ServiceAccount "olm/olm-operator-serviceaccount"
INFO[0006]   Creating ClusterRole "system:controller:operator-lifecycle-manager"
INFO[0006]   Creating ClusterRoleBinding "olm-operator-binding-olm"
INFO[0006]   Creating OLMConfig "cluster"
INFO[0009]   Creating Deployment "olm/olm-operator"
INFO[0009]   Creating Deployment "olm/catalog-operator"
INFO[0009]   Creating ClusterRole "aggregate-olm-edit"
INFO[0009]   Creating ClusterRole "aggregate-olm-view"
INFO[0009]   Creating OperatorGroup "operators/global-operators"
INFO[0009]   Creating OperatorGroup "olm/olm-operators"
INFO[0009]   Creating ClusterServiceVersion "olm/packageserver"
INFO[0010]   Creating CatalogSource "olm/operatorhubio-catalog"
INFO[0010] Waiting for deployment/olm-operator rollout to complete
INFO[0010]   Waiting for Deployment "olm/olm-operator" to rollout: 0 of 1 updated replicas are available
INFO[0021]   Deployment "olm/olm-operator" successfully rolled out
INFO[0021] Waiting for deployment/catalog-operator rollout to complete
INFO[0021]   Deployment "olm/catalog-operator" successfully rolled out
INFO[0021] Waiting for deployment/packageserver rollout to complete
INFO[0021]   Waiting for Deployment "olm/packageserver" to rollout: 0 of 2 updated replicas are available
INFO[0032]   Deployment "olm/packageserver" successfully rolled out
INFO[0032] Successfully installed OLM version "latest"

NAME                                            NAMESPACE    KIND                        STATUS
catalogsources.operators.coreos.com                          CustomResourceDefinition    Installed
clusterserviceversions.operators.coreos.com                  CustomResourceDefinition    Installed
installplans.operators.coreos.com                            CustomResourceDefinition    Installed
olmconfigs.operators.coreos.com                              CustomResourceDefinition    Installed
operatorconditions.operators.coreos.com                      CustomResourceDefinition    Installed
operatorgroups.operators.coreos.com                          CustomResourceDefinition    Installed
operators.operators.coreos.com                               CustomResourceDefinition    Installed
subscriptions.operators.coreos.com                           CustomResourceDefinition    Installed
olm                                                          Namespace                   Installed
operators                                                    Namespace                   Installed
olm-operator-serviceaccount                     olm          ServiceAccount              Installed
system:controller:operator-lifecycle-manager                 ClusterRole                 Installed
olm-operator-binding-olm                                     ClusterRoleBinding          Installed
cluster                                                      OLMConfig                   Installed
olm-operator                                    olm          Deployment                  Installed
catalog-operator                                olm          Deployment                  Installed
aggregate-olm-edit                                           ClusterRole                 Installed
aggregate-olm-view                                           ClusterRole                 Installed
global-operators                                operators    OperatorGroup               Installed
olm-operators                                   olm          OperatorGroup               Installed
packageserver                                   olm          ClusterServiceVersion       Installed
operatorhubio-catalog                           olm          CatalogSource               Installed
```

## Installing an Operator using OLM

When you install OLM, it comes packaged with a number of Operators developed by the community that you can install instantly.
You can use the `packagemanifest` api to see the operators available for you to install in your cluster:

```sh
$ kubectl get packagemanifest -n olm
NAME                                       CATALOG               AGE
# ...
noobaa-operator                            Community Operators   2m17s
project-quay                               Community Operators   2m17s
ack-eks-controller                         Community Operators   2m17s
# ...
```

To install the quay operator in the default namespace, first create an `OperatorGroup` for the default namespace:

```sh
$ cat operatorgroup.yaml
kind: OperatorGroup
apiVersion: operators.coreos.com/v1
metadata:
  name: og-single
  namespace: default
spec:
  targetNamespaces:
  - default

$ kubectl apply -f operatorgroup.yaml
operatorgroup.operators.coreos.com/og-single created
```

Then create a subscription for the quay operator:

```sh
$ cat subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: quay
  namespace: default
spec:
  channel: stable-3.8
  installPlanApproval: Automatic
  name: project-quay
  source: operatorhubio-catalog
  sourceNamespace: olm
  startingCSV: quay-operator.v3.8.1

$ kubectl apply -f subscription.yaml
subscription.operators.coreos.com/quay created
```

This installs the v3.8.1 version of the quay operator, and then upgrades to the latest version of the quay operator in your cluster.

```sh
$ kubectl get sub -n default
NAME   PACKAGE        SOURCE                  CHANNEL
quay   project-quay   operatorhubio-catalog   stable-3.8

$ kubectl get csv -n default
NAME                   DISPLAY   VERSION   REPLACES               PHASE
quay-operator.v3.8.3   Quay      3.8.3     quay-operator.v3.8.1   Succeeded

$ kubectl get deployment -n default
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
quay-operator-tng   1/1     1            1           40s
```

To learn more about packaging your operator for OLM, installing/uninstalling an operator etc, visit the [Core Tasks](/docs/tasks/) and the [Advanced Tasks](/docs/advanced-tasks/) sections of this site.


[sdk-installation-guide]: https://sdk.operatorframework.io/docs/installation/
