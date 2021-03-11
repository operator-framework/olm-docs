---
title: "InstallPlan"
weight: 5
---

An InstallPlan defines a set of resources to be created in order to install or upgrade to a specific version of a ClusterService defined by a CSV.

Operator authors are responsible for defining which `InstallModes` their operator supports within its ClusterServiceVersion (CSV). There are four `InstallModes` that an operator can support:
* `OwnNamespace`: If supported, the operator can be configured to watch for events in the namespace it is deployed in.
* `SingleNamespace`: If supported, the operator can be configured to watch for events in a single namespace that the operator is not deployed in.
* `MultiNamespace`: If supported, the operator can be configured to watch for events in more than one namespace.
* `AllNamespaces`: If supported, the operator can be configured to watch for events in all namespaces.

> Note: If a CSV's spec omits an entry of InstallModeType, that type is considered unsupported unless support can be inferred by an existing entry that implicitly supports it.

Cluster admins cannot override which `InstallMode`s an operator supports, and should understand how to create an `OperatorGroup` that supports each `InstallMode`. Let's look at an example of an `OperatorGroup` implementing each type of `InstallMode`:


# OwnNamespace

When we want to watch ONLY the operator's namespace, we specify the operator's namespace in the `spec.targetNamespaces`. 

> When we want to watch ONLY the operator's namespace, we specify the operator's namespace in the `spec.targetNamespaces`

```yaml
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: the-operators-namespace-operator-group
  namespace: the-operators-namespace
spec:
  targetNamespaces:
  - the-operators-namespace
```

# SingleNamespace

When you want to watch a single namespace that is **NOT** the operator's namespace, we specify that one namespace in the `spec.targetNamespaces` field.

> When you want to watch a single namespace that is **NOT** the operator's namespace, we specify that one namespace in the `spec.targetNamespaces` field.

```yaml
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: single-namespace-operator-group
  namespace: the-operators-namespace
spec:
  targetNamespaces:
  - some-other-namespace
```

# MultiNamespace

When watching multiple namespaces, we need to list out the namespaces in the `spec.targetNamespaces` section. 

> When watching multiple namespaces, we need to list out the namespaces in the `spec.targetNamespaces` section.

```yaml
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: multi-namespace-operator-group
  namespace: the-operators-namespace
spec:
  targetNamespaces:
  - the-operators-namespace
  - some-other-namespace
```

> Please note that MultiNamespace install mode may cause tenancy issues and it is not recommended.

# AllNamespaces

Notice that in the `AllNamespaces` case, we omit the `spec`.

> Notice that in the `AllNamespaces` case, we omit the `spec`.

```yaml
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: all-namespaces-operator-group
  namespace: the-operators-namespace
```
