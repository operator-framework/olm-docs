---
title: Operators
menu:
  main:
    weight: 10
---

## What is an Operator?

An Operator is a method of packaging, deploying and managing a Kubernetes-native application. A Kubernetes-native application is an application that is both deployed on Kubernetes and managed using the Kubernetes APIs and kubectl tooling. An Operator is a piece of software that runs in a Pod inside the Kubernetes cluster and it interacts with the Kubernetes API. It has a reconciler loop that runs continuously, which monitors Objects (Pods, Services, ConfigMaps, or PersistentVolumes) for a desired state given by a Custom Resource Definition (CRD) and replicates that state in the cluster.

Conceptually, Operators take human operational knowledge and encode it into software that is more easily shared with consumers.

Operators are pieces of software that ease the operational complexity of running another piece of software. They act like an extension of the software vendor’s engineering team, watching over a Kubernetes environment (such as OpenShift Container Platform) and using its current state to make decisions in real time. Advanced Operators are designed to handle upgrades seamlessly, react to failures automatically, and not take shortcuts, like skipping a software backup process to save time.

More technically, Operators are a method of packaging, deploying, and managing a Kubernetes application.

A Kubernetes application is an app that is both deployed on Kubernetes and managed using the Kubernetes APIs and `kubectl` or `oc` tooling. To be able to make the most of Kubernetes, you require a set of cohesive APIs to extend in order to service and manage your apps that run on Kubernetes. Think of Operators as the runtime that manages this type of app on Kubernetes.

## What is the difference between a Controller and an Operator

An Operator is an application-specific controller that extends the Kubernetes API to create, configure and manage instances of complex stateful applications on behalf of a Kubernetes user. It is built on top of the basic Kubernetes resource and Kubernetes Controller along with some application-specific knowledge.

We use Operators because managing stateful applications, like databases, caches and monitoring systems, is a big challenge, especially at massive scale. These systems require human operational knowledge to correctly scale, upgrade and reconfigure while at the same time protecting against data loss and unavailability.

All Operators use the controller pattern, but the converse is not true. It's only an Operator if it has API extension and single-app focus in addition to the controller pattern

## What do Operators provide?

- Repeatability of installation and upgrade.
- Constant health checks of every system component.
- Over-the-air (OTA) updates for Kubernetes components and ISV content.
- A place to encapsulate knowledge from field engineers and spread it to all users, not just one or two.


## What is Operator Lifecycle Manager?

Operator Lifecycle Manager (OLM) helps users install, update, and manage the lifecycle of all Operators and their associated services running across their clusters. It is part of the Operator Framework, an open source toolkit designed to manage Kubernetes native applications (Operators) in an effective, automated, and scalable way.


## How does OLM enable cluster admins and Developers?

The OLM is enabled by default in OpenShift Container Platform 4.X, which aids cluster administrators in installing, upgrading, and granting access to Operators running on their cluster. The OpenShift Container Platform web console provides management screens for cluster administrators to install Operators, as well as grant specific projects access to use the catalog of Operators available on the cluster.

For developers, a self-service experience allows provisioning and configuring instances of databases, monitoring, and big data services without having to be subject matter experts, because the Operator has that knowledge baked into it.


## Build with the Operator SDK

The [Operator SDK](https://sdk.operatorframework.io/) provides the tools to build, test and package Operators. The Operator SDK strips away a lot of the boilerplate code that is normally required to integrate with the Kubernetes API. It also provides a usable scaffolding so developers can focus on adding business logic (for example, how to scale, upgrade, or backup the application it manages). Leading practices and code patterns shared across Operators are included in the Operator SDK to help prevent duplicating efforts. The Operator SDK also encourages short, iterative development and test cycles with tooling that allow for basic validation of the Operator, and automated packaging for deployment using the [Operator Lifecycle Manager](https://olm.operatorframework.io/).


## Package with the Operator Lifecycle Manager

With OLM, administrators can control which Operators are available in what namespaces and who can interact with running Operators. The permissions of an Operator are accurately configured automatically to follow a least-privilege approach. OLM manages the overall lifecycle of Operators and their resources, by doing things like resolving dependencies on other Operators, triggering updates to both an Operator and the application it manages, or granting a team access to an Operator for their slice of the cluster.

Simple, stateless applications can use the Lifecycle Management features of the Operator Framework—without writing any code—by using a generic Operator (for example, the Helm Operator). However, complex and stateful applications are where an Operator can be especially useful. The managed-service capabilities that are encoded into the Operator code can provide an advanced user experience, automating such features as updates, backups and scaling.

#### Next steps

See [How to use Operator SDK to build operators](https://sdk.operatorframework.io/build/). And then, check how Operator SDK can help you to [Integrate your Operator with OLM](https://sdk.operatorframework.io/docs/olm-integration/)
