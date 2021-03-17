---
title: "Bundle Index Image"
weight: 3
description: >
    Bundle index image example and references
---

A bundle is an operator packaging construct which contains an operator definition and manifests which ultimately determine how the operator is deployed onto a Kubernetes cluster. Bundles are the preferred mechanism within OLM going forward to package and deploy Operators. Operator developers are encouraged to use the Bundle format over PackageManifests.

To build an Operator index image, we must first have an Operator that is ready to be deployed. To create an Operator, we can use `operator-sdk` to scaffold and construct your Operator. 

Once your Operator is built, the code is built into a container image. If you use [Operator SDK](https://sdk.operatorframework.io/docs/) to build your Operator, it contains a `Makefile` that you can use to build and push your Operator image. To create and push your Operator's image to a registry, use the following command:

```
make docker-build docker-push IMG=<registry>/<username>/sample-operator:vX.X.X
```

### Building the Operator Bundle Image

For an Operator to be deployed it has to be bundled. We can create the Bundle using one of the following command:
```
make bundle IMG=<registry>/<username>/sample-operator:vX.X.X
```

The `make bundle` command also creates a Dockerfile, named bundle.Dockerfile, which is used to build a bundle image. The bundle image is an [OCI](https://github.com/opencontainers/image-spec) image that holds the generated on-disk bundle manifest and metadata files.

### Building the Operator Index Image

Another OLM concept is the "index image", which is like a catalog of Operators. This container image acts to serve an application programming interface (API) which describes information about your sample operator and others in the catalog. An index image, based on the Operator Bundle Format, is a containerized snapshot of a catalog. It is an immutable artifact that contains the database of pointers to a set of Operator manifest content. A catalog can reference an index image to source its content for OLM on the cluster. 

#### Creating an index image:

1. The index image includes information from your bundle image by running the operator-registry's `opm` command  as follows:
```
opm index add --bundles <registry>/<username>/sample-operator-bundle:vX.X.X --tag <registry>/<username>/sample-operator-index:vX.X.X --binary-image <registry_base_image>
```
- A comma separated list of additional bundle images to the index
- The image tag that you want the index image to have.
- Optional: An alternative registry base image to use for serving the catalog.

2. Push the index image to a registry:
```bash
docker push <registry>/<username>/sample-operator-index:vX.X.X
```

The index image holds a database with bundle definitions, it also runs a gRPC service when the image is executed. The gRPC service lets consumers query the database for information about the operators contained in the index.

You can download the `opm` command from the [operator-registry](https://github.com/operator-framework/operator-registry) repository.

#### Creating a catalog from an index image
`
Create a CatalogSource object that references your index image. Modify the following to your specifications and save it as a catalogSource.yaml` file:

```yaml
kind: CatalogSource
metadata:
  name: sample-operator
  namespace: operators
spec:
  sourceType: grpc
  image: <registry>:<port>/<namespace>/sample-operator-index:vX.X.X
  displayName: My Operator Catalog
  publisher: <publisher_name> 
  updateStrategy:
    registryPoll: 
      interval: 30m
```

- Specify your index image
- Specify your name or an organization name publishing the catalog
- Catalog sources can automatically check for new versions to keep up to date

Now we have to apply this yaml file to the Kubernetes cluster:

```bash
kubectl apply -f catalogSource.yaml
```

On OpenShift clusters, the CatalogSource is created by OLM in an existing namespace named `operators`. When you create the CatalogSource, it causes the index image to be executed as a Pod. You can view it as follows:
```
kubectl -n operators get pod --selector=olm.catalogSource=sample-operator
```

#### Updating an index image

After configuring Operator to use a catalog source that references a custom index image that cluster administrators can keep the available Operators on their cluster up to date by adding bundle images to the index image.

```
opm index add --bundles <registry>/<namespace>/<new_bundle_image>:<tag> --from-index <registry>/<namespace>/<existing_index_image>:<tag> --tag <registry>/<namespace>/<existing_index_image>:<tag> 
```

- A comma seperated list of additional bundle images to the index
- The existing index that was previously pushed
- The image tag that you want the updated index image to have


For more references on Bundle Indices please read [Operator Registry docs](https://github.com/operator-framework/operator-registry#building-an-index-of-operators-using-opm) and this [blog](https://www.redhat.com/en/blog/deploying-operators-olm-bundles)