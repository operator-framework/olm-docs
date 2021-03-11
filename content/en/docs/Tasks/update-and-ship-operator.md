---
title: "Update and ship an Operator"
date: 2021-03-10
weight: 2
description: >

--- 

## Introduction

In the Operator Lifecycle Manager (OLM) ecosystem, the following resources are used to resolve Operator installations and upgrades:

1. <b>`ClusterServiceVersion (CSV)`</b> - A YAML manifest created from Operator metadata that assists the Operator Lifecycle Manager (OLM) in running the Operator in a cluster.

    A CSV is the metadata that accompanies an Operator container image, used to populate user interfaces with information like its logo, description, and version. It is also a source of technical information needed to run the Operator, like the RBAC rules it requires and which Custom Resources (CRs) it manages or depends on.

    A CSV is composed of a Metadata, Install strategy, and CRDs.

2. <b>`CatalogSource`</b> - Operator metadata, defined in CSVs, can be stored in a collection called a CatalogSource. CatalogSource contains metadata that OLM can query to discover and install operators with thrie dependencies.

3. <b>`Subscription`</b> - A user indicates a particular package and channel in a particular CatalogSource in a Subscription. Subscription ensures OLM will manage and upgrades/installs the operator to ensure the latest version is always running in the cluster


OLM uses CatalogSources, which use the Operator Registry API, to query for available Operators as well as upgrades for installed Operators.

![CatalogSource Image](https://raw.githubusercontent.com/laxmikantbpandhare/olm-docs/olm-opr-updt/content/en/docs/Tasks/images/catalogsource.png)

<I> <b> Figure 1. CatalogSource overview </b> </I>

In the above image, etcd is a package. Alpha and beta are the channels.

Within a CatalogSource, Operators are organized into packages and streams of updates called channels, which should be a familiar update pattern from OpenShift Container Platform or other software on a continuous release cycle like web browsers.

![Channels Image](https://raw.githubusercontent.com/laxmikantbpandhare/olm-docs/olm-opr-updt/content/en/docs/Tasks/images/channels.png)

<I> <b> Figure 2. Packages and channels in a CatalogSource </b> </I>

A user indicates a particular package and channel in a particular CatalogSource in a Subscription.

For example an etcd package and its alpha channel. If a Subscription is made to a package that has not yet been installed in the namespace, the latest Operator for that package is installed.

> Note: OLM deliberately avoids version comparisons, so the "latest" or "newest" Operator available from a given catalog → channel → package path does not necessarily need to be the highest version number. It should be thought of more as the head reference of a channel, similar to a Git repository.

In the Figure 2, etcd package has two channels as alpha and beta. The alpha channel has three CSV versions `0.9.2`, `0.9.0`, and `0.6.1`. On the other hand, beta channel has two versions `0.9.2` and `0.6.1`. 

## Upgrade flow of an Operator

For an example upgrade scenario, consider an installed Operator corresponding to CSV version `0.1.1`. OLM queries the CatalogSource and detects an upgrade in the subscribed channel with new CSV version `0.1.3` that replaces an older but not-installed CSV version `0.1.2`, which in turn replaces the older and installed CSV version `0.1.1`.

OLM walks back from the channel head to previous versions via the replaces field specified in the CSVs to determine the upgrade path `0.1.3` → `0.1.2` → `0.1.1`; the direction of the arrow indicates that the former replaces the latter. OLM upgrades the Operator one version at the time until it reaches the channel head.

For this given scenario, OLM installs Operator version `0.1.2` to replace the existing Operator version `0.1.1`. Then, it installs Operator version `0.1.3` to replace the previously installed Operator version `0.1.2`. At this point, the installed operator version `0.1.3` matches the channel head and the upgrade is completed.

![Graph Image](https://raw.githubusercontent.com/laxmikantbpandhare/olm-docs/olm-opr-updt-ship/content/en/docs/Tasks/images/graph.png)

<I> <b> Figure 3. OLM's graph of available channel updates </b> </I>

Each CSV has a replaces parameter that indicates which Operator it replaces. This builds a graph of CSVs that can be queried by OLM, and updates can be shared between channels. Channels can be thought of as entry points into the graph of updates.


##### Channels in a package

```yaml
packageName: etcd
channels:
- name: alpha
  currentCSV: etcdoperator.v0.9.0
- name: beta
  currentCSV: etcdoperator.v0.9.2
defaultChannel: alpha
```

For OLM to successfully query for updates, given a `CatalogSource`, `package`, `channel`, and `CSV`, a catalog must be able to return, unambiguously and deterministically, a single CSV that replaces the input CSV.


## Skipping upgrades

OLM's basic path for upgrades is:

- A `CatalogSource` is updated with one or more updates to an Operator.

- OLM traverses every version of the Operator until reaching the latest version the `CatalogSource` contains.

But sometimes this is not a safe operation to perform. There will be cases where a published version of an operator should never be installed on a cluster if it hasn't already (e.g. because that version introduces a serious vulnerability).

In those cases we have to consider two cluster states and provide an update graph that supports both:

- The "bad" intermediate operator has been seen by a cluster and installed
- The "bad" intermediate operator has not yet been installed onto a cluster

By shipping a new catalog and adding a "skipped" release, we can keep our catalog invariant (always get a single unique update) regardless of the cluster state and whether it has seen the bad update yet.

For example:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  name: etcdoperator.v0.9.2
  namespace: placeholder
  annotations:
spec:
    displayName: etcd
    description: Etcd Operator
    replaces: etcdoperator.v0.9.0
    skips:
    - etcdoperator.v0.9.1
```

Consider the following example Old CatalogSource and New CatalogSource:

![Graph Image](https://raw.githubusercontent.com/laxmikantbpandhare/olm-docs/olm-opr-updt-ship/content/en/docs/Tasks/images/skipping.png)
