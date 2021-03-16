---
title: Operator Lifecycle Manager
linkTitle: "Documentation"
menu:
  main:
    weight: 10
---

## What is OLM?

[Operator Lifecycle Manager (OLM)](https://github.com/operator-framework/operator-lifecycle-manager) is a component of the [Operator Framework](https://github.com/operator-framework), an open source toolkit to manage Kubernetes native applications, called Operators, in an effective, automated, and scalable way. OLM extends Kubernetes to provide a declarative way to install, manage, and upgrade Operators and their dependencies in a cluster.

Read more in the [introduction blog post](https://operatorhub.io/what-is-an-operator).

## Why should I use OLM?

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


## How OLM solves the cluster admin and developer needs.

### Operator Installation and Management

This packaging mechanism helps to simplify the multiple steps involved in deploying an Operator. OLM fulfills necessary metadata for visualizing them incompatible UIs, including installation instructions and API hints in the form of CRD descriptors. It helps cluster admin, developers to manage the lifecycle of all Operators and their associated services running across their clusters.

### Dependency Resolution

Using OLM eliminates the need for developers and cluster admins to have to worry about managing dependancies when developing one or more operators. OLM offers dependency resolution and upgrades the lifecycle of running operators. This functionality helps operator developers to resolve the problems related to dependency management.

### Works similar to package Managers

Operator developers may need to use one or more APIs for the operator installation and OLM helps solve this use case by verifying that all of the required APIs are available for the operator. If they are not available, then OLM will not install the operator.

### Operator Groups

To give cluster admins complete control over the permissions that OLM grants operators, OLM introduced the concept of `OperatorGroups`.

* Defines the set of permissions that OLM may grant to member operators
* Defines the set of namespaces that OLM may grant namespaced permissions in.

## Building blocks of OLM

### [ClusterServiceVersion](/docs/concepts/crds/clusterserviceversion)
A `ClusterServiceVersion (CSV)` represents a particular version a running operator on a cluster. It includes metadata such as name, description, version, repository link, labels, icon, etc. 


### [CatalogSource](/docs/concepts/crds/catalogsource/)
A `CatalogSource` represents a store of metadata that OLM can query to discover and install operators and their dependencies.


### [OperatorCondition](/docs/concepts/crds/operatorcondition/)
An `OperatorCondition` is CustomResourceDefinition that creates a communication between OLM and an operator it manages. Operators may write to the `Status.Conditions` array to modify OLM management the operator.


### [Subscriptions](/docs/concepts/crds/subscription)
A `Subscription` represents an intention to install an operator. Subscriptions are Custom Resources that relate an operator to a CatalogSource. Subscriptions describe which [channel](/docs/glossary/#channel) of an operator package to subscribe to and whether to perform updates automatically or manually. If set to automatic, the Subscription ensures OLM will manage and upgrade the operator to ensure the latest version is always running in the cluster.


### [InstallPlan](/docs/concepts/crds/installplan/)
An `InstallPlan` defines a set of resources to be created in order to install or upgrade to a specific version of a ClusterService defined by a CSV.


### [OperatorGroup](/docs/concepts/crds/operatorgroup/)
An `OperatorGroup` is an OLM resource that provides rudimentary multitenant configuration to OLM installed operators.


## Where should I go next?

- [How do I install OLM?](/docs/getting-started/)
- [How do I validate the package?](/docs/tasks/validate-package)
- [How do I install my operator with OLM?](/docs/tasks/install-operator-with-olm/)
- [How do I uninstall an Operator?](/docs/tasks/uninstall-operator)
- [How do I uninstall OLM?](/docs/tasks/uninstall-olm)