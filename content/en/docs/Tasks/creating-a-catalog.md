---
title: "Creating a Catalog of operators"
weight: 3
description: >
  Add/Remove a collection of operators to/from a Catalog
---

## Prerequisites

- [opm](https://github.com/operator-framework/operator-registry/releases) `v1.19.0+` (for file-based catalogs), **OR**
- [opm](https://github.com/operator-framework/operator-registry/releases) `v1.23.1+` (for catalog templates)

>Note: This document discusses creating a catalog of operators using plaintext files to store catalog metadata, which is the [latest feature][file-based-catalog-spec] of OLM catalogs. If you are looking to build catalogs using the deprecated sqlite database format to store catalog metadata instead, please read the [v0.18.z version][v0.18.z-version] of this doc instead.

>Note: `catalog templates` are **ALPHA** functionality and may adopt breaking changes

## Creating a Catalog

`OLM`'s `CatalogSource` [CRD][catalogsource-crd] accepts a container image reference to a catalog of operators that can
be made available to install in a cluster. You can make your operator bundle available to install in a cluster by adding
it to a catalog, packaging the catalog in a container image, and then using that image reference in the `CatalogSource`.
This image contains all of the metadata required for OLM to manage the lifecycle of all of the operators it contains.

OLM uses a plaintext [file-based catalog][file-based-catalog-spec] format (JSON or YAML) to store these records in a Catalog, and there are two approaches we can take to creating a Catalog, adding operators to it, and validating it.
Let's walk through a simple example for both approaches.

### Catalog Creation Using Catalog Templates

[Catalog Templates][templates-doc] are a purpose-built simplification of [File-Based Catalogs][file-based-catalog-spec] to ease common catalog operations.  For this example, we'll be using the [semver template][semver-template-doc].
>Note: We strongly recommend that authors create and maintain their templates in a version-controlled environment discrete from their generated catalogs.  Further, we recommend that authors focus on the template as the sole artifact connecting the operator to the catalog (even going so far as only generating the file-based catalog during CI/CD tooling so it is only provided for catalog contribution.)

#### Catalog Creation

First we need to create the Catalog hierarchy and Dockerfile for generating the image

```sh
$ mkdir -p cool-catalog/example-operator
$ opm generate dockerfile cool-catalog
```

#### Organizing the Bundles into Channels

Let's assume that this isn't the first time that we have released this operator into the catalog, but it's our first foray into templates.  We need to ensure an upgrade graph edge between the older bundle version and the new one.  We also want to promote this latest version in a "stable" channel.  Lastly, we already use [Semantic Versioning](https://semver.org) for our release numbering, and we really only care about new major (e.g. X.\#.\#) releases.

>Note: we presume this step and template processing are performed in the source-controlled location related to operator bundle release, or at least separate from the catalog

```sh
$ cat << EOF >> example-operator-template.yaml
Schema: olm.semver
GenerateMajorChannels: true
GenerateMinorChannels: false
Stable:
  Bundles:
  - Image: repository-uri/example-operator:v0.8.9
  - Image: repository-uri/example-operator:v0.9.0
EOF
```

#### Generating the Catalog

```console
opm alpha render-template semver -o yaml < example-operator-template.yaml > cool-catalog/catalog.yaml
```

Validate the catalog to ensure that the result is functional

```sh
$ opm validate cool-catalog
$ echo $?
0
```

### Catalog Creation with Raw File-Based Catalogs

#### Catalog Creation

First, we need to initialize our Catalog, so we'll make a directory for it, generate a Dockerfile that can build a Catalog
image, and then populate our catalog with our operator.

#### Initializing the Catalog

```sh
$ mkdir cool-catalog
$ opm generate dockerfile cool-catalog
$ opm init example-operator \
    --default-channel=preview \
    --description=./README.md \
    --icon=./example-operator.svg \
    --output yaml > cool-catalog/operator.yaml
```

Let's validate our catalog to see if we're ready to ship!

```sh
$ opm validate cool-catalog
FATA[0000] invalid index:
└── invalid package "example-operator":
    └── invalid channel "preview":
        └── channel must contain at least one bundle
```

Alright, so it's not valid. It looks like we need to add a bundle, so let's do
that next...

#### Add a bundle to the Catalog

```sh
$ opm render quay.io/example-inc/example-operator-bundle:v0.1.0 \
    --output=yaml >> cool-catalog/operator.yaml
```

Let's validate again:

```
$ opm validate cool-catalog
FATA[0000] package "example-operator", bundle "example-operator.v0.1.0" not found in any channel entries
```

#### Add a channel entry for the bundle

We rendered the bundle, but we still haven't yet added it to any channels.
Let's initialize a channel:

```sh
cat << EOF >> cool-catalog/operator.yaml
---
schema: olm.channel
package: example-operator
name: preview
entries:
  - name: example-operator.v0.1.0
EOF
```

Is the third time the charm for `opm validate`?

```sh
$ opm validate cool-catalog
$ echo $?
0
```

Success! There were no errors and we got a `0` error code.

#### Raw File-Based Catalogs Summary

In the general case, adding a bundle involves three discrete steps:

- Render the bundle into the catalog using `opm render <bundleImage>`.
- Add the bundle into desired channels and update the channels' upgrade edges
  to stitch the bundle into the correct place.
- Validate the resulting catalog.

> NOTE: catalog metadata should be stored in a version control system (e.g. `git`) and catalog images should be rebuilt from source
whenever updates are made to ensure that all changes to the catalog are auditable. Here is an example of catalog metadata being stored
in github: <https://github.com/operator-framework/cool-catalog>, with the catalog image being rebuilt whenever there is a change:
<https://github.com/operator-framework/cool-catalog/blob/main/.github/workflows/build-push.yml>.

**Step 1** is just a simple `opm render` command.

**Step 2** has no defined standards other than that the result must pass validation in step 3. Some operator authors may
decide to hand edit channels and upgrade edges. Others may decide to implement automation (e.g. to idempotently
build semver-based channels and upgrade graphs based solely on the versions of the operators in the package). There is
no right or wrong answer for implementing this step as long as `opm validate` is successful.

There are some guidelines to keep in mind though:

- Once a bundle is present in a Catalog, you should assume that one of your users has installed it. With that in mind,
  you should take care to avoid stranding users that have that version installed. Put another way, make sure that
  all previously published bundles in a catalog have a path to the current/new channel head.
- Keep the semantics of the upgrade edges you use in mind. `opm validate` is not able to tell you if you have a sane
  upgrade graph. To learn more about the upgrade graph of an operator, checkout the
  [creating an upgrade graph doc][upgrade-graph-doc].

### Build and push the catalog image

The last step is building and pushing the catalog image.  For either approach, this is the same:

```sh
$ docker build . \
    -f cool-catalog.Dockerfile \
    -t quay.io/example-inc/cool-catalog:latest
$ docker push quay.io/example-inc/cool-catalog:latest
```

Now the catalog image is available for clusters to use and reference with `CatalogSources` on their cluster.

[catalogsource-crd]: /docs/concepts/crds/catalogsource
[file-based-catalog-spec]: /docs/reference/file-based-catalogs
[templates-doc]: /docs/reference/catalog-templates
[semver-template-doc]: /docs/reference/catalog-templates#semver-template
[upgrade-graph-doc]: /docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph
[v0.18.z-version]:  https://v0-18-z.olm.operatorframework.io/docs/tasks/make-index-available-on-cluster/
