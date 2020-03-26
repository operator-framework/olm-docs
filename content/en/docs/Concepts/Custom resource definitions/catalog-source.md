---
title: "Catalog Source"
linkTitle: "Catalog Source"
weight: 5
description: >
  This guide introduces the concept of Catalog Source in OpenShift Lifecycle Manager.
---

{{% alert title="Warning" color="warning" %}}
These pages are under construction. 
**ToDo: Complete this**
{{% /alert %}}

### Definition

The CatalogSource represents a repository of bundles, which are collections of resources that must contain [CSVs](#ClusterServiceVersion), [CRDs](#CustomResourceDefinitions), and package definitions. There are multiple implementations of a CatalogSource backend, the current recommendation is to use a [registry image](#Index).