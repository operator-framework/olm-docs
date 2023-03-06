---
title: "OLM Architecture"
linkTitle: "OLM Architecture"
date: 2020-03-25
weight: 4
description: >
  A discussion on the architecture of Operator Lifecycle Manager (OLM).
---


The Operator Lifecycle Manager is composed of two Operators: the OLM Operator and the Catalog Operator.

Each of these Operators are responsible for managing the CRDs that are the basis for the OLM framework:

**_Table 1. CRDs managed by OLM and Catalog Operators_**

| Resource              | Short Name  | Owner   | Description                           |
|-----------------------|-------------|---------|---------------------------------------|
| ClusterServiceVersion | **csv**     | OLM     | Application metadata: name, version, icon, required resources, installation, etc.  |
| InstallPlan           | **ip**      | Catalog | Calculated list of resources to be created in order to automatically install or upgrade a CSV.  |
| CatalogSource         | **catsrc**  | Catalog | A repository of CSVs, CRDs, and packages that define an application.  |
| Subscription          | **sub**     | Catalog | Used to keep CSVs up to date by tracking a channel in a package.  |
| OperatorGroup         | **og**      | OLM     | Used to group multiple namespaces and prepare them for use by an Operator. |
----------------

Each of these Operators are also responsible for creating resources:

**_Table 2. Resources created by OLM and Catalog Operator_**

| Resource                           | Owner   |
|------------------------------------|---------|
| Deployments                        | OLM     |
| ServiceAccounts                    | OLM     |
| (Cluster)Roles                     | OLM     |
| (Cluster)RoleBindings              | OLM     |
| Custom Resource Definitions (CRDs) | Catalog |
| ClusterServiceVersions (CSVs)      | Catalog |
----------------

## OLM Operator

OLM Operator is responsible for deploying applications defined by CSV resources after the required resources specified in the CSV are present in the cluster.

OLM Operator is not concerned with the creation of the required resources; users can choose to manually create these resources using the CLI, or users can choose to create these resources using the Catalog Operator. This separation of concern enables users incremental buy-in in terms of how much of the OLM framework they choose to leverage for their application.

While the OLM Operator is often configured to watch all namespaces, it can also be operated alongside other OLM Operators so long as they all manage separate namespaces.

### _OLM Operator workflow_

* Watches for ClusterServiceVersion (CSVs) in a namespace and checks that requirements are met. If so, runs the install strategy for the CSV.

{{% alert title="Note" %}}A CSV must be an active member of an OperatorGroup in order for the install strategy to be run.{{% /alert %}}

## Catalog Operator

The Catalog Operator is responsible for resolving and installing CSVs and the required resources they specify. It is also responsible for watching CatalogSources for updates to packages in channels and upgrading them (optionally automatically) to the latest available versions.

A user that wishes to track a package in a channel creates a Subscription resource configuring the desired package, channel, and the CatalogSource from which to pull updates. When updates are found, an appropriate InstallPlan is written into the namespace on behalf of the user.

Users can also create an InstallPlan resource directly, containing the names of the desired CSV and an approval strategy, and the Catalog Operator creates an execution plan for the creation of all of the required resources. After it is approved, the Catalog Operator creates all of the resources in an InstallPlan; this then independently satisfies the OLM Operator, which proceeds to install the CSVs.

### _Catalog Operator workflow_

* Has a cache of CRDs and CSVs, indexed by name.
* Watches for unresolved InstallPlans created by a user:
  * Finds the CSV matching the name requested and adds it as a resolved resource.
  * For each managed or required CRD, adds it as a resolved resource.
  * For each required CRD, finds the CSV that manages it.
* Watches for resolved InstallPlans and creates all of the discovered resources for it (if approved by a user or automatically).
* Watches for CatalogSources and Subscriptions and creates InstallPlans based on them.

## Catalog Registry

The Catalog Registry stores CSVs and CRDs for creation in a cluster and stores metadata about packages and channels.

A _package manifest_ is an entry in the Catalog Registry that associates a package identity with sets of CSVs. Within a package, channels point to a particular CSV. Because CSVs explicitly reference the CSV that they replace, a package manifest provides the Catalog Operator all of the information that is required to update a CSV to the latest version in a channel, stepping through each intermediate version.
