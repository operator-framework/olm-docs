---
title: "Defining user permissions for Operators by Restricting operators"
linkTitle: "Defining user permissions for Operators by Restricting operators"
weight: 4
---

OLM runs with cluster-admin privileges and is capable of granting permissions to operators that it deploys. By default, an operator can specify any set of permission(s) in the CSV and OLM will consequently grant it to the operator.

You can restrict the operator either by
    - Restricting operators to namespaces using operatorgroups.
    - Restricting installing an operator by requiring a remote registry auth token.

## Restricting operators to namespaces using operatorgroups.

When creating `OperatorGroups` it is important to know that an operator may not support all namespace configurations. For example, an operator that is designed to run at the cluster level shouldn't be expected to work in an `OperatorGroup` that defines a single targetNamespace. Operator authors are responsible for defining which `InstallModes` their operator supports within its `ClusterServiceVersion (CSV)`. There are four `InstallModes`-: `OwnNamespace`, `SingleNamespace`, `MultiNamespace` and `AllNamespaces`

The set of namespaces can be hardcoded setting the `spec.targetNamespaces` of an `OperatorGroup` like so:

```yaml
apiVersion: operators.coreos.com/v1alpha2
kind: OperatorGroup
metadata:
  name: my-group
  namespace: my-namespace
spec:
  targetNamespaces:
  - my-namespace
  - my-other-namespace
  - my-other-other-namespace
```

In the above example, member operator will be scoped to the following namespaces:

* my-namespace
* my-other-namespace
* my-other-other-namespace

## Restricting installing an operator by requiring a remote registry auth token

This writeup will be updated soon.