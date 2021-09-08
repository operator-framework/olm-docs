---
title: "Communicating Operator Conditions to OLM"
linkTitle: "Communicating Operator Conditions to OLM"
weight: 3
---

## Communicating Operator Conditions to OLM

As part of its role in managing the lifecycle of an operator, the Operator-Lifecycle-Manager (OLM) infers the state of an operator from the state of Kubernetes resources that define the operator. While this approach provides some level of assurance that an operator is in a given state, there are many instances where an operator may wish to communicate information to OLM that could not be inferred otherwise. This information can then be used by OLM to better manage the lifecycle of the operator.

## OperatorConditions

OLM introduced a new [CustomResourceDefinition](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/) called the [OperatorCondition](/docs/concepts/crds/operatorcondition) allowing operators to communicate conditions to OLM. There are a set of "OLM Supported Conditions" which influence OLM's management of the operator when present in the OperatorCondition's [Status.Conditions](https://github.com/operator-framework/api/blob/b55a341f6560db4adec39d69aab1ff3092ea202a/pkg/operators/v1/operatorcondition_types.go#L22) array.

### OLM Supported Conditions

 The set of "OLM Supported Conditions" include:

* The [Upgradeable](#upgradeable) Condition

#### Upgradeable

The `Upgradeable` "OLM Supported Condition" prevents the existing CSV from being replaced by a newer version of the CSV. When the `Upgradeable` condition is set to `False`, OLM will:

* Prevent a channel entry in a subscribed package that replaces the operator's existing CSV from leaving the PendingPhase.

The `Upgradeable` condition might be useful when:

* An operator is about to start a critical process and should not be upgraded until after the process is completed.
* The operator is performing a migration of CRs that must be completed before the operator is ready to be upgraded.

##### Example Upgradeable OperatorCondition

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorCondition
metadata:
  name: foo-operator
  namespace: operators
status:
  conditions:
  - type: Upgradeable # The name of the `Upgradeable` OLM Supported Condition.
    status: "False"   # The operator is not ready to be upgraded.
    reason: "migration"
    message: "The operator is performing a migration."
    lastTransitionTime: "2020-08-24T23:15:55Z"
```

Given that the `Upgradable Condition`'s status is set to `False`, OLM will understand that it should not upgrade the operator.

### Overriding OperatorConditions

There are times as a Cluster Admin that you may want to ignore an "OLM Supported Condition" reported by an Operator. For example, imagine that a known version of an operator always communicates that it is not upgradeable. In this instance, you may want to upgrade the operator despite the operator communicating that it is not upgradeable. This could be accomplished by overriding the `OLM Supported Condition` by adding the condition's type and status to the `spec.overrides` array in the `OperatorCondition` CR:

"OLM Supported Conditions" can be overridden by Cluster Admins by appending the desired OperatorCondition to the opertor's OperatorCondition's [Spec.Overrides](https://github.com/operator-framework/api/blob/b55a341f6560db4adec39d69aab1ff3092ea202a/pkg/operators/v1/operatorcondition_types.go#L16) Condition Array. When present, "OLM Supported Conditions" in the `Spec.Overrides` array will override the Conditions in the `Status.conditions` array, allowing Cluster Admins to deal with situations where an operator is incorrectly reporting a state to OLM.

#### Example Override

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
    reason: "upgradeIsSafe"
    message: "This is a known issue with the operator where it always reports that it cannot be upgraded."
status:
  conditions:
  - type: Upgradeable
    status: "False"
    reason: "migration"
    message: "The operator is performing a migration."
    lastTransitionTime: "2020-08-24T23:15:55Z"
```

## Updating your operator to use OLM OperatorCondition

OLM will automatically create an `OperatorCondition` for each `ClusterServiceVersion` that it reconciles. All service accounts in the CSV will be granted the RBAC to interact with the `OperatorCondition` owned by the operator.

Operators deployed by OLM may then use the [operator-library](https://github.com/operator-framework/operator-lib/tree/main/conditions) to set conditions on their operator.

### Setting Defaults

In an effort to remain backwards compatible, OLM treats the absence of an `OperatorConditions` as opting out of the condition. Therefore, an operator that opts in to using `OperatorConditions` should set default conditions before the pod's [ready probe](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes) is set to true. This provides the operator with a grace period to update the condition to the correct state.
