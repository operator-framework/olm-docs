---
title: "Building a Catalog"
linkTitle: "Building a Catalog"
date: 2020-04-27
weight: 3
description: >
    Build a Catalog of Operators using [Operator-Registry](https://github.com/operator-framework/operator-registry) 
---

# Manifest format

We refer to a directory of files with one ClusterServiceVersion as a "bundle". A bundle typically includes a ClusterServiceVersion and the CRDs that define the owned APIs of the CSV in its manifest directory, though additional objects may be included. It also includes an annotations file in its metadata folder which defines some higher level aggregate data that helps to describe the format and package information about how the bundle should be added into an index of bundles.
<pre></pre>

```yaml
 # example bundle
 etcd
 ├── manifests
 │   ├── etcdcluster.crd.yaml
 │   └── etcdoperator.clusterserviceversion.yaml
 └── metadata
     └── annotations.yaml
```
<pre></pre>
When loading manifests into the database, the following invariants are validated:
<pre>
 * The bundle must have at least one channel defined in the annotations.
 * Every bundle has exactly one ClusterServiceVersion.
 * If a ClusterServiceVersion `owns` a CRD, that CRD must exist in the bundle.
</pre>
Bundle directories are identified solely by the fact that they contain a ClusterServiceVersion, which provides an amount of freedom for layout of manifests.
<pre></pre>
Check out the [operator bundle design proposal](https://github.com/operator-framework/operator-registry/blob/master/docs/design/operator-bundle.md) for more detail on the bundle format.
<pre></pre>

# Bundle images

Using [OCI spec](https://github.com/opencontainers/image-spec/blob/master/spec.md) container images as a method of storing the manifest and metadata contents of individual bundles, `opm` interacts directly with these images to generate and incrementally update the database. Once you have your [manifests defined](https://operator-framework.github.io/olm-book/docs/packaging-an-operator.html#writing-your-operator-manifests) and have created a directory in the format defined above, building the image is as simple as defining a Dockerfile and building that image:

```Dockerfile
FROM scratch

# We are pushing an operator-registry bundle
# that has both metadata and manifests.
LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=test-operator
LABEL operators.operatorframework.io.bundle.channels.v1=beta,stable
LABEL operators.operatorframework.io.bundle.channel.default.v1=stable

ADD test/*.yaml /manifests
ADD test/metadata/annotations.yaml /metadata/annotations.yaml
```

```sh
podman build -t quay.io/my-container-registry-namespace/my-manifest-bundle:latest -f bundle.Dockerfile .
```

Once you have built the container, you can publish it like any other container image:

```sh
podman push quay.io/my-container-registry-namespace/my-manifest-bundle:latest
```

Of course, this build step can be done with any other OCI spec container tools like `docker`, `buildah`, `libpod`, etc.
<pre></pre>

# Building an index of Operators using opm


<pre></pre>
Index images are additive, so you can add a new version of your operator bundle when you publish a new version:
<pre></pre>
```sh
opm index add --bundles quay.io/my-container-registry-namespace/my-manifest-bundle:0.0.2 --from-index quay.io/my-container-registry-namespace/my-index:1.0.0 --tag quay.io/my-container-registry-namespace/my-index:1.0.1
```
<pre></pre>
For more detail on using `opm` to generate index images, take a look at the [documentation](https://github.com/operator-framework/operator-registry/blob/master/docs/design/opm-tooling.md).
<pre></pre>
## Where should I go next?

* [Use the catalog of operators locally](/docs/concepts/olm-architecture/operator-registry/using-a-catalog-locally): Test your catalog locally 
* [Using a Catalog with OLM](/docs/concepts/olm-architecture/operator-registry/using-catalog-with-olm): Make your operator available for OLM in a cluster


