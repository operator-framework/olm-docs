---
title: "Update and ship an Operator"
date: 2021-03-10
weight: 2
description: > 
    This guide shows OLM users how to create upgrade paths for their operator bundles.
--- 

## Overview

In the Operator Lifecycle Manager (OLM) ecosystem, the following resources are used to resolve Operator installations and upgrades:

1. `ClusterServiceVersion (CSV)` - A YAML manifest created from Operator metadata that assists the Operator Lifecycle Manager (OLM) in running the Operator in a cluster.

    A CSV is the metadata that accompanies an Operator container image, used to populate user interfaces with information like its logo, description, and version. It is also a source of technical information needed to run the Operator, like the RBAC rules it requires and which Custom Resources (CRs) it manages or depends on.

    A CSV is composed of a Metadata, Install strategy, and CRDs.

2. `CatalogSource` - Operator metadata, defined in CSVs, can be stored in a collection called a CatalogSource. CatalogSource contains metadata that OLM can query to discover and install operators with their dependencies.

3. `Subscription` - A user indicates a particular package and channel in a particular CatalogSource in a Subscription. Subscription ensures OLM will manage and upgrades/installs the operator to ensure the latest version is always running in the cluster


OLM uses CatalogSources, which use the Operator Registry API, to query for available Operators as well as upgrades for installed Operators.

![CatalogSource Image](/docs/Tasks/images/catalogsource.png)

`Figure 1. CatalogSource overview`

In the above image, etcd is a package. Alpha and beta are the channels.

Within a CatalogSource, Operators are organized into packages and streams of updates called channels, which should be a familiar update pattern from OpenShift Container Platform or other software on a continuous release cycle like web browsers.

![Channels Image](/docs/Tasks/images/channels.png)

`Figure 2. Packages and channels in a CatalogSource`

A user indicates a particular package and channel in a particular CatalogSource in a Subscription.

For example an etcd package and its alpha channel. If a Subscription is made to a package that has not yet been installed in the namespace, the latest Operator for that package is installed.

> Note: OLM deliberately avoids version comparisons, so the "latest" or "newest" Operator available from a given catalog → channel → package path does not necessarily need to be the highest version number. It should be thought of more as the head reference of a channel, similar to a Git repository.

In the Figure 2, etcd package has two channels as alpha and beta. The alpha channel has three CSV versions `0.9.2`, `0.9.0`, and `0.6.1`. On the other hand, beta channel has two versions `0.9.2` and `0.6.1`. 

## Upgrade flow of an Operator

For an example upgrade scenario, consider an installed Operator corresponding to CSV version `0.1.1`. OLM queries the CatalogSource and detects an upgrade in the subscribed channel with new CSV version `0.1.3` that replaces an older but not-installed CSV version `0.1.2`, which in turn replaces the older and installed CSV version `0.1.1`.

OLM walks back from the channel head to previous versions via the replaces field specified in the CSVs to determine the upgrade path `0.1.3` → `0.1.2` → `0.1.1`; the direction of the arrow indicates that the former replaces the latter. OLM upgrades the Operator one version at the time until it reaches the channel head.

For this given scenario, OLM installs Operator version `0.1.2` to replace the existing Operator version `0.1.1`. Then, it installs Operator version `0.1.3` to replace the previously installed Operator version `0.1.2`. At this point, the installed operator version `0.1.3` matches the channel head and the upgrade is completed.

![Graph Image](/docs/Tasks/images/graph.png)

`Figure 3. OLM's graph of available channel updates`

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

![skipping Image](/docs/Tasks/images/Skipping.png)

`Figure 4. Skipping updates`

In the above example, skips parameters has the version `etcdoperator.v0.9.1`. While upgrading from `0.9.0` to `0.9.2` then it will skip the updates for `0.9.1`. This is beacuse of the version `0.9.1` is marked for skip. 


This graph maintains that:

- Any Operator found in Old CatalogSource has a single replacement in New CatalogSource.

- Any Operator found in New CatalogSource has a single replacement in New CatalogSource.

- If the bad update has not yet been installed, it will never be.

## Replacing Multiple Operators

Creating the New CatalogSource as described requires publishing CSVs that replace one Operator, but can `skip` several. This can be accomplished using the `skipRange` annotation:

        olm.skipRange: <semver_range>

where `<semver_range>` has the version range format supported by the [semver library](https://github.com/blang/semver#ranges).

When searching catalogs for updates, if the head of a channel has a `skipRange` annotation and the currently installed Operator has a version field that falls in the range, OLM updates to the latest entry in the channel.

The order of precedence is:

- Channel head in the source specified by sourceName on the Subscription, if the other criteria for skipping are met.

- The next Operator that replaces the current one, in the source specified by sourceName.

- Channel head in another source that is visible to the Subscription, if the other criteria for skipping are met.

- The next Operator that replaces the current one in any source visible to the Subscription.

`skipRange example:`

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
    name: elasticsearch-operator.v4.1.2
    namespace: placeholder
    annotations:
        olm.skipRange: '>=4.1.0 <4.1.2'
```

## Z-stream support

A z-stream (patch release) needs to replace all previous z-stream releases for the same minor version. OLM doesn't care about major/minor/patch versions, we just need to build the correct graph in a catalog.

In other words, we need to be able to take a graph as in "Old Catalog" and, similar to before, generate a graph as in "New Catalog"

![replace Image](/docs/Tasks/images/replace.png)

`Figure 5. Replacing several Operators`

This graph maintains that:

- Any Operator found in Old CatalogSource has a single replacement in New CatalogSource.

- Any Operator found in New CatalogSource has a single replacement in New CatalogSource.

- Any z-stream release in Old CatalogSource will update to the latest z-stream release in New CatalogSource.

- Unavailable releases can be considered "virtual" graph nodes; their content does not need to exist, the registry just needs to respond as if the graph looks like this.

# Ship Operator

For the shimpment of an operator, first make sure that manifests gets created with the updated version of operator. Check below link for mre details on operator manifest creation process.

[create-operator-manaifest?](/docs/tasks/creating-operator-manifests/)

Then, validate the created manifest or package.

[validate-package?](/docs/tasks/validate-package/)

At the end, make the updated operator package as a part of catalog.

[make-operator-part-of-catalog?](/docs/tasks/make-operator-part-of-catalog/)

