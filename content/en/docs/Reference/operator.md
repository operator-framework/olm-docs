---
title: "Operators"
linkTitle: "Operators"
weight: 3
date: 2021-03-15
description: >
    What are Operators
---

## What is an Operator?

Operators make it easy to manage complex stateful applications on top of Kubernetes. By [Extending the Kubernetes API](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) with CustomResourceDefinitions it is possible to create what we call Operator Projects where you will be able to create and define your own API's to represent your solutions on the cluster and manage them by looking for the desired state. For a better understanding, see the [Operator Pattern][operator-pattern].

## How are Operators and Controllers related?

See that following the [Operator's pattern][operator-pattern]; you will create [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/) which provides a reconcile function responsible for synchronizing the resources until a desired state on the cluster. For a more practical explanation, see also [What’s in a controller?](https://book.kubebuilder.io/cronjob-tutorial/controller-overview.html#whats-in-a-controller).

## What is Operator Lifecycle Manager?

OLM extends Kubernetes to provide a declarative way to install, manage, and upgrade Operators and their dependencies in a cluster. It provides the following features:

### Over-the-Air Updates and Catalogs
Kubernetes clusters are being kept up to date using elaborate update mechanisms today, more often automatically and in the background. Operators, being cluster extensions, should follow that. OLM has a concept of catalogs from which Operators are available to install and being kept up to date. In this model OLM allows maintainers granular authoring of the update path and gives commercial vendors a flexible publishing mechanism using channels.

### Dependency Model
With OLMs packaging format Operators can express dependencies on the platform and on other Operators. They can rely on OLM to respect these requirements as long as the cluster is up. In this way, OLMs dependency model ensures Operators stay working during their long lifecycle across multiple updates of the platform or other Operators.

### Discoverability
OLM advertises installed Operators and their services into the namespaces of tenants. They can discover which managed services are available and which Operator provides them. Administrators can rely on catalog content projected into a cluster, enabling discovery of Operators available to install.

### Cluster Stability
Operators must claim ownership of their APIs. OLM will prevent conflicting Operators owning the same APIs being installed, ensuring cluster stability.

### Declarative UI controls
Operators can behave like managed service providers. Their user interface on the command line are APIs. For graphical consoles OLM annotates those APIs with descriptors that drive the creation of rich interfaces and forms for users to interact with the Operator in a natural, cloud-like way.


## How does OLM enable cluster admins and developers?

The OLM is enabled by default in OpenShift Container Platform 4.x, which aids cluster administrators in installing, upgrading, and granting access to Operators running on their cluster. The OpenShift Container Platform (OCP) web console provides management screens for cluster administrators to install Operators, as well as grant specific projects access to use the catalog of Operators available on the cluster.

For developers, a self-service experience allows provisioning and configuring instances of databases, monitoring, and big data services without having to be subject matter experts, because the Operator has that knowledge baked into it.

## Build with the Operator SDK

[Operator SDK][osdk] is also a component of the [Operator Framework][operator-framework]. Writing an operator today can be difficult because of challenges such as using low-level APIs, writing boilerplate, and a lack of modularity which leads to duplication.
The [Operator SDK][osdk] is a framework that uses the [controller-runtime][controller-runtime] library to make writing operators easier by providing:

- High-level APIs and abstractions to write the operational logic more intuitively
- Tools for scaffolding and code generation to bootstrap a new project fast
- Extensions to cover common operator use cases

Note that [Operator SDK][osdk] provides helpers and features to help you [integrate your project with OLM][olm-integration].

## Package with the Operator Lifecycle Manager

With OLM, administrators can control which Operators are available in what namespaces and who can interact with running Operators. The permissions of an Operator are accurately configured automatically to follow a least-privilege approach. OLM manages the overall lifecycle of Operators and their resources, by doing things like resolving dependencies on other Operators, triggering updates to both an Operator and the application it manages, or granting a team access to an Operator for their slice of the cluster.

Simple, stateless applications can use the Lifecycle Management features of the Operator Framework—without writing any code—by using a generic Operator (for example, the Helm Operator). However, complex and stateful applications are where an Operator can be especially useful. The managed-service capabilities that are encoded into the Operator code can provide an advanced user experience, automating features such as updates, backups and scaling.


[osdk]: https://sdk.operatorframework.io/
[operator-framework]: https://github.com/operator-framework
[controller-runtime]: https://github.com/kubernetes-sigs/controller-runtime
[olm-integration]: https://sdk.operatorframework.io/docs/olm-integration/
[operator-pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
