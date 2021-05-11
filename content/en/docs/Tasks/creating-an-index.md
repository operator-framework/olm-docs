---
title: "Creating an Index of operator bundles"
weight: 3
description: >
  Add/Remove a collection of bundles to/from an Index
---

## Prerequisites 

- [opm](https://github.com/operator-framework/operator-registry/releases) `v1.14.0+`
- [docker](https://docs.docker.com/install/) version `17.03`+ or [podman](https://github.com/containers/libpod/blob/master/install.md) `v1.2.0+` or [buildah](https://github.com/containers/buildah/blob/master/install.md) `v1.7+`.


# Creating an Index 

`OLM`'s `CatalogSource` [CRD][catalogsource-crd] define a reference to a catalog of operators that are available to install onto a cluster. To make your operator bundle available, you can add the bundle to a container image which the `CatalogSource` points to. This image contains a record of bundle images that OLM can pull and extract the manifests from in order to install an operator. 

>Note: The container image also contains information that represents the upgrade graphs between different operator versions, an operator's dependencies etc graphically. To learn more about the upgrade graph of an operator, checkout the [creating an upgrade graph doc][upgrade-graph-doc]  

So, to make your operator available to OLM, you can generate an index image via opm with your bundle reference included:

```sh
$ opm index add --bundles quay.io/my-container-registry-namespace/my-manifest-bundle:0.0.1 --tag quay.io/my-container-registry-namespace/my-index:1.0.0
$ podman push quay.io/my-container-registry-namespace/my-index:1.0.0
```

The resulting image is referred to as an `Index`. Now that image is available for clusters to use and reference with `CatalogSources` on their cluster.

`Index` images are additive, so you can add a new version of your operator bundle when you publish a new version of your operator:

```bash
$ opm index add --bundles quay.io/my-container-registry-namespace/my-manifest-bundle:0.0.2 --from-index quay.io/my-container-registry-namespace/my-index:1.0.0 --tag quay.io/my-container-registry-namespace/my-index:1.0.1
```

### Other operations on an Index using `opm` 

The `opm index` command contains additional sub-commands that can be used to perform different operations like remove an operator from an index, prune an index of all but specified operators etc. Please checkout the documentation under `opm index -h` for more information. 
 

[catalogsource-crd]: /docs/concepts/crds/catalogsource
[upgrade-graph-doc]: /docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph 