---
title: "Operators"
linkTitle: "Operators"
weight: 3
date: 2021-03-15
---
## What is an Operator?

Operators make it easy to manage complex stateful applications on top of Kubernetes. By [Extendig the Kubernetes API with CustomResourceDefinitions](https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/) it is possible to create what we call Operator Projects where you will be able to create and define your own API's to represent your solutions on the cluster and managed them by looking for the desired state. For a better understanding see [Operator Pattern][operator-pattern]

## What is the difference between a Controller and an Operator

See that following the [Operator's pattern][operator-pattern]; you will create [Controllers](https://kubernetes.io/docs/concepts/architecture/controller/) which provides a reconcile function responsible for synchronizing the resources until a desired state on the cluster. For a more practical explanation, see also [What’s in a controller?](https://book.kubebuilder.io/cronjob-tutorial/controller-overview.html#whats-in-a-controller)

## What is Operator Lifecycle Manager?

Operator Lifecycle Manager (OLM) helps users install, update, and manage the lifecycle of all Operators and their associated services running across their clusters. This project is a component of the [Operator Framework][operator-framework], an open-source toolkit to manage Kubernetes native applications, called Operators, in an effective, automated, and scalable way. Read more in the introduction [blog post](https://www.openshift.com/blog/introducing-the-operator-framework?extIdCarryOver=true&sc_cid=701f2000001Css5AAC).

## How does OLM enable cluster admins and Developers?

The OLM is enabled by default in OpenShift Container Platform 4.X, which aids cluster administrators in installing, upgrading, and granting access to Operators running on their cluster. The OpenShift Container Platform web console provides management screens for cluster administrators to install Operators, as well as grant specific projects access to use the catalog of Operators available on the cluster.

For developers, a self-service experience allows provisioning and configuring instances of databases, monitoring, and big data services without having to be subject matter experts, because the Operator has that knowledge baked into it.


## Build with the Operator SDK

[Operator SDK][osdk] is also a component of the [Operator Framework][operator-framework]. Writing an operator today can be difficult because of challenges such as using low-level APIs, writing boilerplate, and a lack of modularity which leads to duplication.
The [Operator SDK][osdk] is a framework that uses the [controller-runtime][controller-runtime] library to make writing operators easier by providing:
- High-level APIs and abstractions to write the operational logic more intuitively
- Tools for scaffolding and code generation to bootstrap a new project fast
- Extensions to cover common operator use cases

Note that [Operator SDK][osdk] provides helpers and features to help you [integrate your project with OLM][olm-integration].  For further information check https://sdk.operatorframework.io/ .


## Package with the Operator Lifecycle Manager

With OLM, administrators can control which Operators are available in what namespaces and who can interact with running Operators. The permissions of an Operator are accurately configured automatically to follow a least-privilege approach. OLM manages the overall lifecycle of Operators and their resources, by doing things like resolving dependencies on other Operators, triggering updates to both an Operator and the application it manages, or granting a team access to an Operator for their slice of the cluster.

Simple, stateless applications can use the Lifecycle Management features of the Operator Framework—without writing any code—by using a generic Operator (for example, the Helm Operator). However, complex and stateful applications are where an Operator can be especially useful. The managed-service capabilities that are encoded into the Operator code can provide an advanced user experience, automating such features as updates, backups and scaling.


[osdk]: https://sdk.operatorframework.io/
[operator-framework]: https://github.com/operator-framework
[controller-runtime]: https://github.com/kubernetes-sigs/controller-runtime
[olm-integration]: https://sdk.operatorframework.io/docs/olm-integration/
[operator-pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
