# How to update an Operator?

## Introduction

In the Operator Lifecycle Manager (OLM) ecosystem, the following resources are used to resolve Operator installations and upgrades:

1. `ClusterServiceVersion (CSV)` - A YAML manifest created from Operator metadata that assists the Operator Lifecycle Manager (OLM) in running the Operator in a cluster.

A CSV is the metadata that accompanies an Operator container image, used to populate user interfaces with information like its logo, description, and version. It is also a source of technical information needed to run the Operator, like the RBAC rules it requires and which Custom Resources (CRs) it manages or depends on.

A CSV is composed of a Metadata, Install strategy, and CRDs.

2. `CatalogSource` - Operator metadata, defined in CSVs, can be stored in a collection called a CatalogSource.

3. `Subscription` - A user indicates a particular package and channel in a particular CatalogSource in a Subscription.


OLM uses CatalogSources, which use the Operator Registry API, to query for available Operators as well as upgrades for installed Operators.

![CatalogSource Image](https://github.com/laxmikantbpandhare/olm-docs/blob/olm-opr-updt/content/en/docs/Tasks/images/catalogsource.png)