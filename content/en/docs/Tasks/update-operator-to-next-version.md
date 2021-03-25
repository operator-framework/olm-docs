---
title: "Update operator to next version"
date: 2021-03-09
weight: 2
description: >
   This guide shows OLM users how to upgrade their operator bundles and how to distribute the new versions of the projects.
--- 

## Overview

In the Operator Lifecycle Manager (OLM) ecosystem, the following resources are used to resolve Operator installations and upgrades:

1. `ClusterServiceVersion (CSV)` - A YAML manifest created from Operator metadata that assists the Operator Lifecycle Manager (OLM) in running the Operator in a cluster.

2. `CatalogSource` - Operator metadata, defined in CSVs, can be stored in a collection called a CatalogSource.

3. `Subscription` - A user indicates a particular package and channel in a particular CatalogSource in a Subscription.


OLM uses CatalogSources, which use the Operator Registry API, to query for available Operators as well as upgrades for installed Operators.

![CatalogSource Image](/docs/Tasks/images/catalogsource.png)


## Steps to update the operator

Within a CatalogSource, Operators are organized into packages and streams of updates called `channels`, which should be a familiar update pattern from OpenShift Container Platform or other software on a continuous release cycle like web browsers.

![Channels Image](/docs/Tasks/images/channels.png)

In the above image, etcd is a package. Alpha and beta are the channels.

1. A user indicates a particular package and channel in a particular CatalogSource in a Subscription.

2. If a Subscription is made to a package that has not yet been installed in the namespace, the latest Operator for that package is installed.
   If the specified version is not available for installation then the most recent updated version of operator gets installed.

## How upgrade works

For an example upgrade scenario, consider an installed Operator corresponding to CSV version `0.1.1`. OLM queries the CatalogSource and detects an upgrade in the subscribed channel with new CSV version `0.1.3` that replaces an older but not-installed CSV version `0.1.2`, which in turn replaces the older and installed CSV version `0.1.1`.

OLM walks back from the channel head to previous versions via the replaces field specified in the CSVs to determine the upgrade path `0.1.3` → `0.1.2` → `0.1.1`; the direction of the arrow indicates that the former replaces the latter. OLM upgrades the Operator one version at the time until it reaches the channel head.

For this given scenario, OLM installs Operator version `0.1.2` to replace the existing Operator version `0.1.1`. Then, it installs Operator version `0.1.3` to replace the previously installed Operator version `0.1.2`. At this point, the installed operator version `0.1.3` matches the channel head and the upgrade is completed.

## Below links for more details

- [Update Operator](/docs/tasks/update-and-ship-operator)



