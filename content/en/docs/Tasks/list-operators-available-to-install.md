---
title: "List operators available to install"
date: 2017-01-05
weight: 5
description: >
   List operators from a collection of catalogs
---

## List your operator

Once you've packaged your operator and made it part of catalog, you can see it among the list of operators that are available to install in the cluster. There is an extension API in OLM named `PackageManifest` that contains information about existing [CatalogSources](/docs/concepts/crds/catalogsource), which is essentially a collection of bundles that each define an operator in the cluster. By querying that API, you can see the list of available operators. 

[CatalogSources](/docs/concepts/crds/catalogsource) in OLM are either global or namespaced. Global CatalogSources contain operators that will be available for installing in all namespaces, while namespaced CatalogSources only contains operators that are available to be installed in a specific namespace.

### Using the PackageManifest API

The `PackageManifest` API when queried, will return the union of globally available as well as namespaced available operators, from the namespace you're querying in.

```bash
kubectl get packagemanifest -n <namespace>
```

The list of available operators will be displayed as an output of those above commands:

```bash
$ kubectl get packagemanifest
NAME                               CATALOG               AGE
cassandra-operator                 Community Operators   26m
etcd                               Community Operators   26m
postgres-operator                  Community Operators   26m
prometheus                         Community Operators   26m
wildfly                            Community Operators   26m
```
