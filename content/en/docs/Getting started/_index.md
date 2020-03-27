---
title: "Getting Started"
linkTitle: "Getting Started"
date: 2020-03-25
weight: 2
description: >
  Install OLM in a kubernetes cluster.
---


{{% alert title="Warning" color="warning" %}}
These pages are under construction. TODO: Check Prerequisites and update 
{{% /alert %}}


## Prerequisites

- [git](https://git-scm.com/downloads)
- [go](https://golang.org/dl/) version `v1.12+`.
- [docker](https://docs.docker.com/install/) version `17.03`+.
  - Alternatively [podman](https://github.com/containers/libpod/blob/master/install.md) `v1.2.0+` or [buildah](https://github.com/containers/buildah/blob/master/install.md) `v1.7+`
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) `v1.11.3+`.
- Access to a Kubernetes `v1.11.3+` cluster.

## Installation

### Install Released OLM
For installing release versions of OLM, for example version 0.12.0, you can use the following command:

```bash
export olm_release=0.12.0
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${olm_release}/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${olm_release}/olm.yaml
```

Learn more about available releases [here](https://github.com/operator-framework/operator-lifecycle-manager/releases).


To deploy OLM locally on a [minikube cluster](https://kubernetes.io/docs/tasks/tools/install-minikube/) for development work, use the `run-local` target in the [Makefile](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Makefile).

```bash
git clone https://github.com/operator-framework/operator-lifecycle-manager.git
cd operator-lifecycle-manager
make run-local
```

## Try it out!

You can verify your installation of OLM by first checking for all the neccesasary CRDs in the cluster:

```bash
$ kubectl get crd
NAME                                          CREATED AT
catalogsources.operators.coreos.com           2019-10-21T18:15:27Z
clusterserviceversions.operators.coreos.com   2019-10-21T18:15:27Z
installplans.operators.coreos.com             2019-10-21T18:15:27Z
operatorgroups.operators.coreos.com           2019-10-21T18:15:27Z
subscriptions.operators.coreos.com            2019-10-21T18:15:27Z
```

And then inspecting the deployments of OLM and it's related components:

```bash
$ kubectl get deploy -n olm
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
catalog-operator   1/1     1            1           5m52s
olm-operator       1/1     1            1           5m52s
packageserver      2/2     2            2           5m43s
```
