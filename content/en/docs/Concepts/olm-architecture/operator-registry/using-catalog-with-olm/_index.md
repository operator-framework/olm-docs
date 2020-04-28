---
title: "Using the Catalog with OLM"
linkTitle: "Using the Catalog with OLM"
date: 2020-03-25
weight: 3
description: >
  Make your operator available for OLM in a cluster
---


To add a [catalog image](/operator-registry/tasks/building-catalog/#building-a-catalog-image-of-operators-using-operator-registry) to your cluster for use with [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager) (OLM), create a [CatalogSource](/docs/Concepts/crds/CatalogSource) referencing the image you created and pushed to your favourite container registry:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: example-manifests
  namespace: default
spec:
  sourceType: grpc
  image: example-registry:latest
```

This will download the referenced image and start a pod in the designated namespace (`default`). Watch the catalog pods to verify it's starting its `gRPC` frontend correctly:

```sh
$ kubectl logs example-manifests-wfh5h -n default

time="2019-03-18T10:20:14Z" level=info msg="serving registry" database=bundles.db port=50051
```

Once the catalog has been loaded, your Operators package definitions are read by the `package-server`, a component of OLM. Watch your Operator packages become available:

```sh
$ watch kubectl get packagemanifests

[...]

NAME                     AGE
prometheus               13m
etcd                     27m
```

Once loaded, you can query a particular package for its Operators that it serves across multiple channels. To obtain the default channel run:

```sh
$ kubectl get packagemanifests etcd -o jsonpath='{.status.defaultChannel}'

alpha
```

With this information, the operators package name, the channel and the name and namespace of your catalog you can now [subscribe](/docs/tasks/install-operator-with-olm/) to Operators with Operator Lifecycle Manager. This represents an intent to install an Operator and get subsequent updates from the catalog:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: etcd-subscription
  namespace: default 
spec:
  channel: alpha
  name: etcd
  source: example-manifests
  sourceNamespace: default
```