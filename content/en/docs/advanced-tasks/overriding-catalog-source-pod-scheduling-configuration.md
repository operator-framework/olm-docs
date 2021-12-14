---
title: "Overriding CatalogSource Pod Scheduling Configuration"
linkTitle: "CatalogSource Pod Scheduling Overrides"
weight: 3
---

## Overriding CatalogSource Pod Scheduling Configuration

When given a CatalogSource of type `grpc` with `spec.image` defined, the `catalog` operator will create 
Pod that serves the content in `spec.image`. By default, this pod defines in its spec no `tolerations`, no `priorityClassName`,
and only the following node selector: `kubernetes.io/os=linux`. These values can be overriden with CatalogSource's
`spec.grpcPodConfig`. For instance,

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: operatorhubio-catalog
  namespace: olm
spec:
  sourceType: grpc
  image: quay.io/operatorhubio/catalog:latest
  displayName: Community Operators
  publisher: OperatorHub.io

  # optional
  grpcPodConfig:
    # override nodeSelector
    # for more information on nodeSelectors see:
    # https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector
    # optional
    nodeSelector:
      custom_label: value
    
    # change priorityClassName
    # kubernetes ships with: system-cluster-critical and system-node-critical
    # setting it to empty ("") will assign the pod the default priority.
    # Other priority classes can be defined manually. For more information on priority classes see:
    # https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass
    # optional
    priorityClassName: system-cluster-critical

    # override tolerations
    # for more information on taints and tolerations see:
    # https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration
    # optional
    tolerations:
      - key: "key1"
        operator: "Equal"
        value: "value1"
        effect: "NoSchedule"
```

As can be seen in the example, `spec.grpcPodConfig` and all of its attributes are optional. These attributes are: `nodeSelector`, `priorityClassName`, and `tolerations`. It should be noted that `priorityClassName` can be overriden to be `""`. This will give the pod the default priority. Any value
outside `system-cluster-critical`, `system-node-critical`, and `""` will need to correspond to a pre-existing and custom defined [priorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass).

Previously, the only pod scheduling parameter that could be overriden was the `priorityClassName`. This was done by adding the following annotation to the `CatalogSource` CR: `operatorframework.io/priorityclass`. For instance:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: operatorhubio-catalog
  namespace: olm
  annotations:
    # kubernetes ships with: system-cluster-critical and system-node-critical
    # setting it to empty ("") will assign the pod the default priority.
    # Other priority classes can be defined manually. For more information on priority classes see:
    # https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/#priorityclass
    # optional
    operatorframework.io/priorityclass: system-cluster-critical
spec:
  sourceType: grpc
  image: quay.io/operatorhubio/catalog:latest
  displayName: Community Operators
  publisher: OperatorHub.io
```

**NOTE**: If a `CatalogSource` CR defines both the annotation and `spec.grpcPodConfig.priorityClassName`, the **annotation** will take precedence over the configuration parameter.
