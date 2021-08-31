---
title: "Creating an Index of operator bundles"
weight: 3
description: >
  Add/Remove a collection of bundles to/from an Index
---

## Prerequisites

- [opm](https://github.com/operator-framework/operator-registry/releases) `v1.18.0+`

## Creating an Index

`OLM`'s `CatalogSource` [CRD][catalogsource-crd] defines a reference to a catalog of operators that are available to
install onto a cluster. To make your operator bundle available, you can add the bundle to a container image which the
`CatalogSource` points to. This image contains a record of bundle images that OLM can pull and extract the manifests
from in order to install an operator.

OLM uses a plaintext [file-based catalog][file-based-catalog-spec] format (JSON or YAML) to store these records in an index, and `opm` has tooling
that helps initialize an index, render new records into it, and then validate that the index is valid. Let's walk
through a simple example.

First, we need to initialize our index, so we'll make a directory for it, generate a Dockerfile that can build an index
image, and then populate our index with our package definition.


### Initialize the index
```sh
$ mkdir example-operator-index
$ opm alpha generate dockerfile example-operator-index
$ opm init example-operator \
    --default-channel=preview \
    --description=./README.md \
    --icon=./example-operator.svg \
    -output yaml > example-operator-index/index.yaml
```

Let's validate our index to see if we're ready to ship!
```sh
$ opm validate example-operator-index
FATA[0000] invalid index:
└── invalid package "example-operator":
    └── invalid channel "preview":
        └── channel must contain at least one bundle
```

Alright, so it's not valid. It looks like we need to add a bundle, so let's do
that next...

### Add a bundle to the index

```sh
$ opm render quay.io/example-inc/example-operator-bundle:v0.1.0 \
    --output=yaml > example-operator-index/index.yaml
```

Let's validate again:
```sh
$ opm validate example-operator-index
```

Success! There were no errors and we got a `0` error code.

In the general case, adding a bundle involves three discreet steps:
1. Render the bundle into the index using `opm render <bundleImage>`
2. Add the bundle into desired channels and update the channels' upgrade edges
   to stitch the bundle into the correct place.
3. Validate the resulting index.

> NOTE: Index metadata should be stored in a version control system (e.g. `git`) and index images should be rebuilt from source
whenever updates are made to ensure that all index changes are auditable.

**Step 1** is just a simple `opm render` command.

**Step 2** has no defined standards other than that the result must pass validation in step 3. Some operator authors may
decide to hand edit channels and upgrade edges. Others may decide to implement automation (e.g. to idempotently
build semver-based channels and upgrade graphs based solely on the versions of the operators in the package). There is
no right or wrong answer for implementing this step as long as `opm validate` is successful.

There are some guidelines to keep in mind though:
1. Once a bundle is present in an index, you should assume that one of your users has installed it. With that in mind,
   you should take care to avoid stranding users that have that version installed. Put another way, make sure that
   all previously published bundles in an index have a path to the current/new channel head.
2. Keep the semantics of the upgrade edges you use in mind. `opm validate` is not able to tell you if you have a sane
   upgrade graph. To learn more about the upgrade graph of an operator, checkout the
  [creating an upgrade graph doc][upgrade-graph-doc]

### Build and push the index image

Lastly, we can build and push our index:

```sh
$ docker build . \
    -f example-operator-index.Dockerfile \
    -t quay.io/example-inc/example-operator-index:latest 
$ docker push quay.io/example-inc/example-operator-index:latest
```

The resulting image is referred to as an `Index`. Now that image is available for clusters to use and reference with
`CatalogSources` on their cluster.

[catalogsource-crd]: /docs/concepts/crds/catalogsource
[file-based-catalog-spec]: /docs/reference/file-based-catalogs
[upgrade-graph-doc]: /docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph 
