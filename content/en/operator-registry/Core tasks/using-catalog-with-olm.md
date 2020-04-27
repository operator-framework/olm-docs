---
title: "Using catalog with OLM"
linkTitle: "Using catalog with OLM"
date: 2020-03-25
weight: 3
description: >
  Make your operator available for OLM
---


To add a catalog packaged with `operator-registry` to your cluster for use with [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager) (OLM) create a `CatalogSource` referencing the image you created and pushed above:

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

With this information, the operators package name, the channel and the name and namespace of your catalog you can now [subscribe](https://github.com/operator-framework/operator-lifecycle-manager#discovery-catalogs-and-automated-upgrades) to Operators with Operator Lifecycle Manager. This represents an intent to install an Operator and get subsequent updates from the catalog:

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