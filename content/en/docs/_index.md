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

## When to use OLM

The premise of an Operator is to have it be a custom form of Controllers. A controller is basically a software loop that runs continuously on the Kubernetes master nodes. In these loops the control logic looks at certain Kubernetes objects of interest. It audits the desired state of these objects, expressed by the user, compares that to what’s currently going on in the cluster and then does anything in its power to reach the desired state. Now, When you have multiple operators running across one or more of these clusters the Operator Lifecycle Manager (OLM) helps users install, update, and manage the lifecycle of all Operators and their associated services.

The OLM runs by default in OpenShift Container Platform, which aids cluster administrators in installing, upgrading, and granting access to Operators running on their cluster. The OpenShift Container Platform web console provides management screens for cluster administrators to install Operators, as well as grant specific projects access to use the catalog of Operators available on the cluster.

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


## Understanding sample OLM use-cases to get started.

An operator needs to support multiple scenarios such as:
- on demand operator deployments
- taking and restoring backups of the application's state
- handling upgrades of the application code alongside related changes such as database schemas or extra configuration settings
- publishing a Service to applications that don't support Kubernetes APIs to discover them
- simulating failure in all or part of your cluster to test its resilience

Multi-cluster environments can have multiple operators performing various dedicated tasks, and as they scale the use case of managing the operators becomes more important. The Operator Lifecycle Manager (OLM) enables developers and developer admins address scalability needs by helping users install, update, and manage the lifecycle of all Operators and their associated services running across their clusters.

## Where should I go next?

