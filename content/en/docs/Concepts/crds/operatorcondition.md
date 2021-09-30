---
title: "OperatorCondition"
weight: 4
---

An `OperatorCondition` is CustomResourceDefinition that creates a communication between OLM and an operator it manages. Operators may write to the `Status.Conditions` array to modify OLM management the operator.

Here's an example of an `OperatorCondition` CustomResource:

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorCondition
metadata:
  name: foo-operator
  namespace: operators
spec:
  overrides:
  - type: Upgradeable # Allows the cluster admin to change operator's Upgrade readiness to True
    status: "True"
    reason: "upgradeIsSafe" # optional
    message: "The cluster admin wants to make the operator eligible for an upgrade." # optional
status:
  conditions:
  - type: Upgradeable
    status: "False"
    reason: "migration"
    message: "The operator is performing a migration."
    lastTransitionTime: "2020-08-24T23:15:55Z"
```
