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

You can verify your installation of OLM by first checking for all the neccesasary CRDs in the cluster:

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

## Installing an Operator using OLM 

When you install OLM, it comes packaged with a number of Operators developed by the community that you can install instantly. 
You can use the `pacakagemanifest` api to see the operators available for you to install in your cluster: 

```sh 
$ kubectl get packagemanifest -n olm
NAME                               CATALOG               AGE
cassandra-operator                 Community Operators   26m
etcd                               Community Operators   26m
postgres-operator                  Community Operators   26m
prometheus                         Community Operators   26m
wildfly                            Community Operators   26m
```

To install the etcd operator in the default namespace, first create an `OperatorGroup` for the default namespace: 

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

$ kubectl apply -f operaotorgroup.yaml
operatorgroup.operators.coreos.com/og-single created
```

Then create a subscription for the etcd operator: 

```sh 
$ cat subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: etcd
  namespace: default
spec:
  channel: singlenamespace-alpha
  installPlanApproval: Automatic
  name: etcd
  source: operatorhubio-catalog
  sourceNamespace: olm
  startingCSV: etcdoperator.v0.9.2

$ kubectl apply -f subscription.yaml
subscription.operators.coreos.com/etcd created
```

This installs the v0.9.2 version of the etcd operator, and then upgrades to the latest version of the etcd operator in your cluster.

```sh
$ kubectl get sub -n default 
NAME   PACKAGE   SOURCE                  CHANNEL
etcd   etcd      operatorhubio-catalog   singlenamespace-alpha

$ kubectl get csv -n default 
NAME                  DISPLAY   VERSION   REPLACES              PHASE
etcdoperator.v0.9.4   etcd      0.9.4     etcdoperator.v0.9.2   Succeeded

$ kubectl get deployment -n default 
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
etcd-operator   1/1     1            1           3m29s
```

To learn more about packaging your operator for OLM, installing/uninstalling an operator etc, visit the [Core Tasks](/docs/tasks/) and the [Advanced Tasks](/docs/advanced-tasks/) section of this site.
