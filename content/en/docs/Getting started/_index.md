---
title: "Getting Started"
linkTitle: "Getting Started"
weight: 2
description: >
  What does your user need to know to try your project?
---

## Prerequisites

- [git][git_tool]
- [go][go_tool] version v1.12+.
- [docker][docker_tool] version 17.03+.
  - Alternatively [podman][podman_tool] `v1.2.0+` or [buildah][buildah_tool] `v1.7+`
- [kubectl][kubectl_tool] version v1.11.3+.
- Access to a Kubernetes v1.11.3+ cluster.

## Installation

## Install Released OLM
For installing release versions of OLM, for example version 0.12.0, you can use the following command:

```bash
export olm_release=0.12.0
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${olm_release}/crds.yaml
kubectl apply -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${olm_release}/olm.yaml
```

Learn more about available releases [here](https://github.com/operator-framework/operator-lifecycle-manager/releases).

## Install From Git Repository Master Branch

You can install OLM from the master branch of the [operator-framework/operator-lifecycle-manager](https://github.com/operator-framework/operator-lifecycle-manager/) repository with the following: 

```bash
kubectl create -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/crds.yaml
kubectl create -f https://raw.githubusercontent.com/operator-framework/operator-lifecycle-manager/master/deploy/upstream/quickstart/olm.yaml
```
You can also clone the entire git repository and use the [Makefile](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/Makefile) for deploying OLM locally on [minikube](https://kubernetes.io/docs/tasks/tools/install-minikube/) for development purposes.

```bash
git clone https://github.com/operator-framework/operator-lifecycle-manager.git
cd operator-lifecycle-manager
make run-local
```

## Verify OLM Install

You can verify the necessary CustomResourceDefinitions are created from applying the `crds.yaml` file with the following:

```bash
$ kubectl get crd
NAME                                          CREATED AT
catalogsources.operators.coreos.com           2019-10-21T18:15:27Z
clusterserviceversions.operators.coreos.com   2019-10-21T18:15:27Z
installplans.operators.coreos.com             2019-10-21T18:15:27Z
operatorgroups.operators.coreos.com           2019-10-21T18:15:27Z
subscriptions.operators.coreos.com            2019-10-21T18:15:27Z
```
You can also visualize OLM deployments from applying `olm.yaml` file with the following:

```bash
$ kubectl get deploy -n olm
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
catalog-operator   1/1     1            1           5m52s
olm-operator       1/1     1            1           5m52s
packageserver      2/2     2            2           5m43s
```

## Setup

Is there any initial setup users need to do after installation to try your project?

## Try it out!

Can your users test their installation, for example by running a commmand or deploying a Hello World example?