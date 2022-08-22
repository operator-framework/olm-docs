---
title: "Overriding Operator Pod Affinity Configuration"
linkTitle: "Operator Pod Affinity Overrides"
weight: 3
---

## Overriding Operator Pod Affinity Configuration

Pods can be configured to be scheduled in particular nodes using [affinity and anti-affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity) constraints. Namely, [node affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity), and [pod affinity and anti-affinity](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity). These constraints can enable users to have high-grained control over where pods are scheduled in the cluster, e.g. to schedule them on nodes running with cheaper architectures, such as arm64, or to improve service resilience by ensuring pod replicas are never scheduled on the same node. In OLM, the `Subscription` API can be used to override operator pod's affinity configuration, thus giving users the ability to override or define their own affinity settings for operator deployments.

The affinity settings for an operator deployment pod defined by the operator author can be overriden in `Subscription.config.affinity`, i.e.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: my-package
  namespace: my-namespace
spec:
  name: my-package
  source: my-operators
  sourceNamespace: operator-registries
  config:
    affinity:
      nodeAffinity:
        ...
      podAffinity:
        ...
      podAntiAffinity:
        ...

```

### Example: Overriding/Defining Node Affinity

The operator `nodeAffinity` configuration can be overriden in the following way:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: my-package
  namespace: my-namespace
spec:
  name: my-package
  source: my-operators
  sourceNamespace: operator-registries
  config:
   affinity:
     nodeAffinity:
       requiredDuringSchedulingIgnoredDuringExecution:
         nodeSelectorTerms:
         - matchExpressions:
           - key: kubernetes.io/arch
             operator: In
             values:
             - amd64
```

Note that this will completely override the `nodeAffinity` configuration defined in the operator deployment pod spec defined by the author.

### Example: Removing Operator Author defined Affinity

The empty object `{}` can be used to remove any affinity definition already defined in the operator deployment pod spec, e.g.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: my-package
  namespace: my-namespace
spec:
  name: my-package
  source: my-operators
  sourceNamespace: operator-registries
  config:
    affinity: {}
```

If equivalent to no affinity configuration. And,

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: my-package
  namespace: my-namespace
spec:
  name: my-package
  source: my-operators
  sourceNamespace: operator-registries
  config:
    affinity:
      podAffinity: {}
      podAntiAffinity: {}
```

Is equivalent to keeping the original `nodeAffinity`, while removing the original `podAffinity` and `podAnitAffinity` configurations.