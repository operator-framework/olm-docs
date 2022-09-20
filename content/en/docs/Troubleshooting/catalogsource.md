---
title: "CatalogSource"
linkTitle: "CatalogSource"
date: 2020-03-25
weight: 2
description: >
  Tips and tricks related to troubleshooting the configuration of a `CatalogSource`.
---

## Prerequisites

- [yq](https://github.com/mikefarah/yq)

## How to debug a failing CatalogSource

The [Catalog operator][olm-arch-doc] will constantly update the `Status` of `CatalogSources` to reflect its current state. You can check the `Status` of your `CatalogSource` with the following command:

`$ kubectl get catsrc my-catalog -n <namespace> -o yaml | yq e '.status' -`

>Note: It is possible that the `Status` is missing, which suggests that the Catalog operator is encountering an issue when processing the `CatalogSource` in a very early stage.

If the `Status` block does not provide enough information, check the [Catalog operator's logs](/docs/troubleshooting/olm-and-catalog-operators/#how-to-view-the-catalog-operator-logs).

If you are still unable to identify the cause of the failure, check if a pod was created for the `CatalogSource`. If a pod exists, review the pod's yaml and logs:

```bash
$ kubectl -n my-namespace get pods
NAME                                READY   STATUS    RESTARTS   AGE
my-catalog-ltdlp         1/1     Running   0          8m31s

$ kubectl -n my-namespace get pod my-catalog-ltdlp -o yaml
...

$ kubectl -n my-namespace logs my-catalog-ltdlp
...
```

### I'm not sure if a specific version of an operator is available in a CatalogSource

First verify that the `CatalogSource` contains the operator that you want to install:

```bash
$ kubectl -n my-namespace get packagemanifests
NAME                               CATALOG             AGE
...
portworx                           My Catalog Source   14m
postgres-operator                  My Catalog Source   14m
postgresql                         My Catalog Source   14m
postgresql-operator-dev4devs-com   My Catalog Source   14m
prometheus                         My Catalog Source   14m
...
```

If the operator is present, check if the version you want is available:

`$ kubectl -n my-namespace get packagemanifests my-operator -o yaml`

### My CatalogSource cannot pull images from a private registry

If you are attempting to pull images from a private registry, make sure to specify a secret key in the `CatalogSource.Spec.Secrets` field.

[olm-arch-doc]: /docs/concepts/olm-architecture#catalog-operator
