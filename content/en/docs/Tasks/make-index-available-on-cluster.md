---
title: "Make an index available on Cluster"
date: 2021-04-28
weight: 4
description: >
    Create a CatalogSource with your index
---

Once you have an `Index` of operators, you can make it available on cluster by referencing it from a `CatalogSource`.


For example, if you have an index image `quay.io/my-namespace/my-index:latest`, you can create a CatalogSource with your index image: 

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-index
  namespace: operator
spec:
  sourceType: grpc
  image: quay.io/my-namespace/my-index:latest
  displayName: My Index
  publisher: Me
  updateStrategy:
    registryPoll:
      interval: 10m
```

### Catalog scoping
By default, a CatalogSource is scoped to the namespace in which it is created in. For example, a CatalogSource in namespace `A` can only be used in dependency resolution for subscriptions that originate in namespace `A` as well. A subscription in another namespace that references the CatalogSource in `A` will not be able to use the catalog contents for dependency resolution. This provides some basic multitenancy: CatalogSource in one namespace do not interfere with CatalogSource in another. 

However, there is one special namespace, by default the `olm` namespace, which acts as a global catalog namespace. CatalogSources in this namespace can be used for dependency resolution in any other namespace. Installing a catalog in the `olm` namespace will make it available as a subscription target for any namespace on the cluster. The global namespace is configurable via the `OPERATOR_NAMESPACE` environment variable on the OLM operator deployment spec. 

### Explanation of spec.updateStrategy

It is possible to configure the `CatalogSource` to poll a source, such as an image registry, to check whether the catalog source pod should be updated. A common use case would be pushing new bundles to the same catalog source tag, and seeing updated operators from those bundles being installed in the cluster. Currently polling is only implemented for image-based catalogs that serve bundles over gRPC.

For example, say currently you have Operator X v1.0 installed in the cluster. It came from a the `Index` `quay.io/my-namespace/my-index:master`. This is the latest version of the X operator in the `Index`. When a new v2.0 of Operator X is available, the index image can be rebuilt to include the v2.0 version of the X operator(with `opm index add`) and pushed to the same master tag. With catalog polling enabled, OLM will pull down the newer version of the index image and route service traffic to the newer pod. The existing subscription to your operator will seamlessly install the v2.0 operator and remove the old v1.0 installation.

Each type of check for an updated catalog source is called an `updateStrategy`. Only one `updateStrategy` is supported at a time. `registryPoll` is a type of `updateStrategy` that checks an image registry for an updated version of the same tag(via image SHAs). The `interval` defines the amount of time between each successive poll.

#### Caveats

- The polling sequence is not instantaneous - it can take up to 15 minutes from each poll for the new catalog source pod to be deployed into the cluster. It may take longer for larger clusters.
- Because OLM pulls down the image every poll interval and starts the pod, to see if its updated, the updated catalog pod must be able to be scheduled onto the cluster. If the cluster is at absolutely maximum capacity, without autoscaling enabled, this feature may not work.
- OLM checks to see whether the container ImageID has changed between the old and new catalog source image when determining if an upgrade is in order. It does not actually parse the image content itself to check for later CSVs. If there is a bad upgrade to the catalog source image, simply overwrite the tag with another version and it will be pulled down, or delete and recreate the catalog source.
- The polling interval should be reasonably high to ensure the update functionality works as intended. Avoid intervals less than 15m.

### Using registry images that require authentication as index/bundle/operator/operand images 

If certain images are hosted in an authenticated container image registry, also known as a private registry, OLM is unable to pull the images by default. To enable access, you can create a pull secret that contains the authentication credentials for the registry. By referencing one or more pull secrets in a `CatalogSource`, OLM can handle placing the secrets in the operator and catalog namespace to allow installation.

> Note: Bundle images that require authentication to pull are handled by this method. Other images required by an Operator or its Operands might require access to private registries as well. OLM does not handle placing the secrets in target tenant namespaces for this scenario, but authentication credentials can be added to the global cluster pull secret or individual namespace service accounts to enable the required access. Alternatively, if providing access to the entire cluster is not permissible, the pull secret can be added to the `default` service accounts of the target tenant namespaces.

To use images from private registries as index/bundle images, create a secret for each required private registry. Once you have the secrets, `kubectl apply` your secrets to the cluster, and the create or update an existing `CatalogSource` object to reference one or more secrets to add a `spec.secrets` section and specify all secrets.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: my-index
  namespace: operator
spec:
  sourceType: grpc
  secrets: 
  - "<secret_name_1>"
  - "<secret_name_2>"
  image: quay.io/my-namespace/my-index:latest
  displayName: My Index
  publisher: Me
  updateStrategy:
    registryPoll:
      interval: 10m
```

