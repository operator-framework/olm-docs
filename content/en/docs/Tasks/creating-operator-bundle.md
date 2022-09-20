---
title: "Creating an Operator Bundle"
date: 2021-01-11
weight: 2
description: >
    Create an operator bundle using the operator manifests
---
## Prerequisites

- [opm](https://github.com/operator-framework/operator-registry/releases)
- [docker](https://docs.docker.com/install/) version `17.03`+ or [podman](https://github.com/containers/libpod/blob/master/install.md) `v1.2.0+` or [buildah](https://github.com/containers/buildah/blob/master/install.md) `v1.7+`.

# Operator Bundle

An Operator Bundle is a container image that stores Kubernetes manifests and metadata associated with an operator. A bundle is meant to represent a specific version of an operator on cluster. Once you have the [ClusterServiceVersion(CSV) for your operator](/docs/tasks/creating-operator-manifests), you can create an operator bundle using the CSV and the CRDs for your operator.

We refer to a directory of files with one ClusterServiceVersion as a `bundle` that includes a CSV and the CRDs in its manifest directory, though additional kubernetes objects may be included. The directory also includes an annotations file in its metadata folder which defines some higher level aggregate data that helps to describe the format and package information about how the bundle should be added into a catalog of bundles. Finally, a Dockerfile can be built from the information in the directory to build the operator bundle image.

```
 # example bundle
 etcd
 ├── manifests
 │   ├── etcdcluster.crd.yaml
 │   └── etcdoperator.clusterserviceversion.yaml
 ├── metadata
 │   └── annotations.yaml
 └── Dockerfile
```

### Contents of annotations.yaml and the Dockerfile

The `annotations.yaml` and the `Dockerfile` can be generated using the `opm` tool's `alpha bundle generate` command.

```sh
Usage:
  opm alpha bundle generate [flags]

Flags:
  -c, --channels string    The list of channels that bundle image belongs to
  -e, --default string     The default channel for the bundle image
  -d, --directory string   The directory where bundle manifests for a specific version are located.
  -h, --help               help for generate
  -u, --output-dir string  Optional output directory for operator manifests
  -p, --package string     The name of the package that bundle image belongs to

  Note:
  * All manifests yaml must be in the same directory.
```
For example, to generate the `annotations.yaml` and `Dockerfile` for the example bundle mentioned above, the command for the `generate` task is:

```bash
$ opm alpha bundle generate --directory /etcd --package etcd --channels stable --default stable
```
After the generate command is executed, the `Dockerfile` is generated in the directory where command is run. By default, the `annotations.yaml` file is located in a folder named `metadata` in the same root directory as the input directory containing manifests.

If the `--output-dir` parameter is specified, that directory becomes the parent for a new pair of folders `manifests/` and `metadata/`, where `manifests/` is a copy of the passed in directory of manifests and `metadata/` is the folder containing annotations.yaml:

```bash
$ tree etcd
etcd
├── manifests
│   ├── etcdcluster.crd.yaml
│   └── etcdoperator.clusterserviceversion.yaml
├── my-output-manifest-dir
│   ├── manifests
│   │   ├── etcdcluster.crd.yaml
│   │   └── etcdoperator.clusterserviceversion.yaml
│   └── metadata
│       └── annotations.yaml
└── Dockerfile
```

The `annotations.yaml` contains the following information as labels that are used to annotate the operator bundle container image:

* The label `operators.operatorframework.io.bundle.mediatype.v1` reflects the media type or format of the operator bundle. It could be helm charts, plain Kubernetes manifests etc.
* The label `operators.operatorframework.io.bundle.manifests.v1 `reflects the path in the image to the directory that contains the operator manifests. This label is reserved for the future use and is set to `manifests/` for the time being.
* The label `operators.operatorframework.io.bundle.metadata.v1` reflects the path in the image to the directory that contains metadata files about the bundle. This label is reserved for the future use and is set to `metadata/` for the time being.
* The `manifests.v1` and `metadata.v1` labels imply the bundle type:
    * The value `manifests.v1` implies that this bundle contains operator manifests.
    * The value `metadata.v1` implies that this bundle has operator metadata.
* The label `operators.operatorframework.io.bundle.package.v1` reflects the package name of the bundle.
* The label `operators.operatorframework.io.bundle.channels.v1` reflects the list of channels the bundle is subscribing to when added into an operator registry
* The label `operators.operatorframework.io.bundle.channel.default.v1` reflects the default channel an operator should be subscribed to when installed from a registry. This label is optional if the default channel has been set by previous bundles and the default channel is unchanged for this bundle.

The `annotations.yaml` file generated in the example above would look like:

```yaml
annotations:
  operators.operatorframework.io.bundle.mediatype.v1: "registry+v1"
  operators.operatorframework.io.bundle.manifests.v1: "manifests/"
  operators.operatorframework.io.bundle.metadata.v1: "metadata/"
  operators.operatorframework.io.bundle.package.v1: "etcd"
  operators.operatorframework.io.bundle.channels.v1: "stable"
  operators.operatorframework.io.bundle.channel.default.v1: "stable"
```

The `Dockerfile` generated in the example above would look like:

```Dockerfile
FROM scratch

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=test-operator
LABEL operators.operatorframework.io.bundle.channels.v1=beta,stable
LABEL operators.operatorframework.io.bundle.channel.default.v1=stable

ADD test/*.yaml /manifests
ADD test/metadata/annotations.yaml /metadata/annotations.yaml
```

# Bundle images

An Operator Bundle is built as a scratch (i.e non-runnable) container image that contains information about the operator manifests and metadata inside the image(stored in a database inside the image). The image can then be pushed and pulled from an [OCI-compliant](https://github.com/opencontainers/image-spec/blob/master/spec.md) container registry.

The `opm` tool can be used to interact directly with these images. Once you have your manifests defined and have created a directory in the format defined above, building the image is as simple as defining a Dockerfile and building that image:

```
```

```sh
$ podman build -t quay.io/my-container-registry-namespace/my-manifest-bundle:latest -f bundle.Dockerfile .
```

Once you have built the container, you can publish it like any other container image:

```sh
$ podman push quay.io/my-container-registry-namespace/my-manifest-bundle:latest
```

Of course, this build step can be done with any other OCI spec container tools like `docker`, `buildah`, `libpod`, etc

## Validating your bundle

Once you've created your bundle, you will want to ensure that your bundle is valid and in the correct format. The [api][api-repo] library contains a validation library that is used by operator-framework tools like `operator-sdk` and `opm` to validate operator bundles. For more information on validating via the `operator-sdk` see the [`operator-sdk bundle validate` documentation][sdk-bundle-validate].

The `opm alpha bundle validate` command will validate a bundle image from a remote registry to determine if its format and content information are accurate.
The following validators will run by default on every invocation of the command.

- CSV validator - validates the CSV name and replaces fields.
- CRD validator - validates the CRDs OpenAPI V3 schema.
- Bundle validator - validates the bundle format and annotations.yaml file as well as the optional dependencies.yaml file.

For example:

`$ opm alpha bundle validate --tag quay.io/test/test-operator:latest --image-builder docker`

### Optional Validation

Some validators are disabled by default and can be optionally enabled via the `--optional-validators` or `-o` flag.

- Operatorhub validator - performs operatorhub.io validation which will check your bundle against the common criteria to distributed with OLM. To validate a bundle using custom categories use the `OPERATOR_BUNDLE_CATEGORIES` environmental variable to point to a json-encoded categories file. Enable this option via `--optional-validators=operatorhub`. This validator allows you to validate that your manifests can work with a Kubernetes cluster of a particular version using the `k8s-version` optional key value. (e.g. `--optional-values=k8s-version=1.22`)
- Bundle objects validator - performs validation on resources like `PodDisruptionBudgets` and `PriorityClasses`. Enable this option via `--optional-validators=bundle-objects`.
Multiple optional validators can be enabled at once, for example `--optional-validators=operatorhub,bundle-objects`.
- Community validator - performs community operator bundle validation which will check your bundle against the criteria to distribute your project on the [Community Catalogs](https://github.com/operator-framework/community-operators). For further information see its [docs](https://operator-framework.github.io/community-operators/). This validator allows you to validate the required labels in the catalog image by using the `index-path` optional key value. (e.g. `--optional-values=index-path=bundle.Dockerfile`).

#### Custom bundle categories

The operatorhub validator can verify against custom bundle categories by setting the `OPERATOR_BUNDLE_CATEGORIES` environment variable.
Setting the `OPERATOR_BUNDLE_CATEGORIES` environment variable to the path to a json file containing a list of categories will enable those categories to be used when comparing CSV categories for operatorhub validation. The json file should be in the following format:

```json
{
   "categories":[
      "Cloud Pak",
      "Registry",
      "MyCoolThing",
   ]
}
```

For example:

`$ OPERATOR_BUNDLE_CATEGORIES=./validate/categories.json ./bin/opm alpha bundle validate --tag <bundle-tag> --image-builder docker -o operatorhub`
will validate the bundle using the provided categories file.

If `OPERATOR_BUNDLE_CATEGORIES` is not set, and operatorhub validation is enabled, the default categories will be used when performing operatorhub validation. The default categories are the following:

- AI/Machine Learning
- Application Runtime
- Big Data
- Cloud Provider
- Developer Tools
- Database
- Integration & Delivery
- Logging & Tracing
- Monitoring
- Networking
- OpenShift Optional
- Security
- Storage
- Streaming & Messaging

[api-repo]: https://github.com/operator-framework/api/tree/master/pkg/validation
[sdk-bundle-validate]: https://sdk.operatorframework.io/docs/cli/operator-sdk_bundle_validate/#operator-sdk-bundle-validate
