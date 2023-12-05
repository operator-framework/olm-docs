---
title: "Make a Catalog available on Cluster"
date: 2021-04-28
weight: 4
description: >
    Create a CatalogSource with your catalog image
---

Once you have a catalog of operators, you can make it available on cluster by referencing it from a `CatalogSource`.


For example, if you have a catalog image `quay.io/my-namespace/cool-catalog:latest`, you can create a CatalogSource with your image: 

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: cool-catalog
  namespace: operator
spec:
  sourceType: grpc
  image: quay.io/my-namespace/cool-catalog:latest
  displayName: Coolest Catalog
  publisher: Me
  updateStrategy:
    registryPoll:
      interval: 10m
```

### Explanation of spec.updateStrategy

When you create a `CatalogSource`, it deploys a pod that serves the content you've stored in the catalog via a grpc API endpoint. 

```bash 
$ kubectl apply -f cool-catalog.yaml 
catalogsource.operators.coreos.com/cool-catalog created

$ kubectl get catsrc
NAME                  DISPLAY               TYPE   PUBLISHER   AGE
cool-catalog       Coolest Catalog          grpc      Me       38s


$ kubectl get pods
NAME                  READY   STATUS    RESTARTS   AGE
cool-catalog-dtqv2     1/1    Running      0       30s
```

It is possible to configure the `CatalogSource` to poll a source, such as an image registry, to check whether the catalog source pod should be updated. A common use case would be pushing new bundles to the same catalog source tag, and seeing updated operators from those bundles being installed in the cluster. 

For example, say currently you have Operator X v1.0 installed in the cluster from the catalog `quay.io/my-namespace/cool-catalog:main`. This is the latest version of the X operator in the catalog. When a new v2.0 of Operator X is published, the v2.0 version of the X operator can be included in the catalog using the same steps described in the [creating catalog doc][creating-a-catalog-steps], then the catalog image can be rebuilt and pushed to the same `main` tag. With catalog polling enabled, OLM will pull down the newer version of the catalog image and make the new information available. 

Each type of check for an updated catalog source is called an `updateStrategy`. Only one `updateStrategy` is supported at a time. `registryPoll` is a type of `updateStrategy` that checks an image registry for an updated version of the same tag(via image SHAs). The `interval` defines the amount of time between each successive poll.

#### Caveats

- The polling sequence is not instantaneous - it can take up to 15 minutes from each poll for the new catalog source pod to be deployed into the cluster. It may take longer for larger clusters.
- Because OLM pulls down the image every poll interval and starts the pod, to see if its updated, the updated catalog pod must be able to be scheduled onto the cluster. If the cluster is at absolutely maximum capacity, without autoscaling enabled, this feature may not work.
- OLM checks to see whether the container ImageID has changed between the old and new catalog source image when determining if an upgrade is in order. It does not actually parse the image content itself to check for later CSVs. If there is a bad upgrade to the catalog source image, simply overwrite the tag with another version and it will be pulled down, or delete and recreate the catalog source.
- The polling interval should be reasonably high to ensure the update functionality works as intended. Avoid intervals less than 15m.

### Using registry images that require authentication as Catalog/bundle/operator/operand images 

If certain images are hosted in an authenticated container image registry, i.e a private registry, OLM is unable to pull the images by default. To enable access, you can create a pull secret that contains the authentication credentials for the registry. By referencing one or more pull secrets in a `CatalogSource`, OLM can handle placing the secrets in the operator and catalog namespace to allow installation.

> Note: Bundle images that require authentication to pull are handled by this method. Other images required by an Operator or its Operands might require access to private registries as well. OLM does not handle placing the secrets in target tenant namespaces for this scenario, but authentication credentials can be added to the global cluster pull secret or individual namespace service accounts to enable the required access. Alternatively, if providing access to the entire cluster is not permissible, the pull secret can be added to the `default` service accounts of the target tenant namespaces.

To use images from private registries as Catalog/bundle images, create a secret for each required private registry. Once you have the secrets, `kubectl apply` your secrets to the cluster, and the create or update an existing `CatalogSource` object to reference one or more secrets to add a `spec.secrets` section and specify all secrets.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: cool-catalog
  namespace: operator
spec:
  sourceType: grpc
  secrets: 
  - "<secret_name_1>"
  - "<secret_name_2>"
  image: quay.io/my-namespace/cool-catalog:latest
  displayName: Coolest Catalog
  publisher: Me
  updateStrategy:
    registryPoll:
      interval: 10m
```

If the `imagePullSecret` is referenced in the bundle, for instance when the controller-manager image is pulled from a private registry, there is no place in the API to tell OLM to attach the `imagePullSecrets`. As a consequence, permissions to pull the image should be added directly to the operator Deployment's manifest by adding the required secret name to the list `deployment.spec.template.spec.imagePullSecrets`. 

For the [operator-sdk](https://sdk.operatorframework.io/) abstraction, the operator Deployment's manifest is found under `config/manager/manager.yaml`. Below is an example of a controller-manager Deployment's manifest configured with an `imagePullSecret` to pull container images from a private registry.

```yaml
# config/manager/manager.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: controller-manager
  namespace: system
  ...
spec:
    ...
    spec:
      imagePullSecrets:
      - name: "registry-auth-secret-name"
```

> Note: It is required for the `imagePullSecret` to be present in the same namespace where the controller is deployed for the controller pod to start.


[creating-a-catalog-steps]: /docs/tasks/creating-a-catalog/#creating-a-catalog
