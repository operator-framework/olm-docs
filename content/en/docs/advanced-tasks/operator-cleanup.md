---
title: "Enabling Operator Cleanup"
linkTitle: "Enabling Operator Cleanup"
weight: 3
---

**Warning: Deleting operator workloads automatically can potentially result in unrecoverable data loss for the user. Be sure to fully understand the consequences of enabling cleanup for your operator, as it can result in unexpected loss of data.**

OLM lets operator users opt-in to the cleanup of their operator workloads, known as Custom Resources (CRs) or operands, when the operator is deleted. The CRs would be deleted upon the uninstallation of the operator by removing the operator CSV. When uninstalling an operator, OLM would delete all CRs managed by an operator so that the operator can be triggered to clean up all the resources associated with its CRs via Finalizers.

By design when OLM uninstalls an operator it does not remove any CRs reconciled by the operator in order to prevent data loss. The operator user is expected to manually delete the CRs that they've created. However, operators that do have cleanup logic implemented via Finalizers or garbage collection owner references benefit from an automatic cleanup of all their managed resources when the operator is uninstalled. This cleanup of CRs and resources would have to happen before the operator is removed so it can process the deletion events of its CRs.

To facilitate an operator's cleanup logic, OLM can optionally delete any CRs provided by an operator before removing it.

Operand cleanup does not currently involve deleting any other resources associated with the operator, such as its CRDs. 

![Operand Cleanup Process](/img/operand-deletion.png)


## Enabling Operator Workload Cleanup
The user can opt into cleanup of the Custom Resources (CRs) reconciled by the operator by a field on the spec which OLM will honor. 

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
...
  spec:
  ...
    cleanup: 
      enabled: true
```

When OLM sees that the CSV cleanup setting is set to `true` it will automatically put the `operatorframework.io/cleanup-apis`
finalizer on the CSV. When the CSV is deleted by the user, kubernetes sets the deletion timestamp on the CSV but the finalizer prevents the 
CSV from being deleted. OLM then finds and deletes all CRs managed by the operator by looking at the operator's `OwnedCRDs` section of the CSV
and then deleting all instances of these CRs on-cluster. By deleting the CRs before removing the operator, OLM allows the operator to run custom cleanup logic on the CRs (via its own finalizers). 

### Operand cleanup status
To provide visibility on the status of operand cleanup, OLM lists out the CRs that are still pending deletion in the CSV status in the CSV.status.cleanup.pendingDeletion block. 

This information can be useful when debugging a stalled operator uninstall process to see the CRs whose removal is blocking operand cleanup.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
...
status:
  ...
  cleanup:
    pendingDeletion:
    - resource: etcdclusters.etcd.database.coreos.com
      kind: EtcdCluster
```


Once the operator removes its finalizers and all CRs have been deleted from the cluster, OLM removes the `operatorframework.io/cleanup-apis` finalizer from the CSV which enables the operator to be deleted from the cluster. 

## Disabling Operator Workload Cleanup
By default, operator workload cleanup is disabled, and when the CSV is deleted the CRs remain on-cluster. To disable the cleanup, switch the setting to false. 
```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
...
  spec:
  ...
    cleanup: 
      enabled: false
```
This will prevent OLM from cleaning up operands upon deletion of the CSV. Note that this setting can also be applied as cleanup occurs, in the case of a bad or stalled cleanup. By switching the setting to `false` the `operatorframework.io/cleanup-apis` finalizer on the CSV is removed and the operator can be removed, but this does not provide guarantees that the CRs themselves have been removed from the cluster. 

## Caveats 
Opting in to operand cleanup is risky, and edge-cases can result in undefined behavior and data loss for users. The following are examples of some edge case scenarios and how OLM deals with them to ensure stability on-cluster for users of this feature.

Scenario:
A CSV on-cluster owns a particular CRD via its `OwnedCRDs` section. A user installs a second CSV manually that own the same CRD and has cleanup enabled. Even though OLM does not allow two CSV's to own the same CRD and the newer CSV does not reach a succeed state, removing it can trigger cleanup of the custom resources of the first CSV, resulting in unintended data loss. 

Solution: OLM ensures that only one CSV owns a particular CRD before attempting to remove the CRs associated with that CSV. 

Scenario: A CSV on-cluster owns a particular CRD via its `OwnedCRDs` section and has cleanup enabled. A user installs a second CSV manually that requires the first CRD via the `RequiredCRDs` portion of its spec meaning that it relies on the first CRD to exist on cluster. If the first CSV is deleted, the CRD remains on cluster, but the operator and its operands are all removed, which may result in data loss for users of the second CSV. 

Solution: OLM does not allow automatic cleanup of CSVs that have other CSVs relying on their CRDs. 

Scenario: A CSV on-cluster owns a particular CRD via its `OwnedCRDs` section and has cleanup enabled. This CSV is meant to only operate within one namespace. The CSV has had its target namespaces annotation (applied by OLM during CSV reconcilation) modified manually by a user. If the CSV is removed, cleanup of CRs may occur unintentionally in other namespaces. 

Solution: OLM looks directly at the OperatorGroup spec for target namespaces instead of the CSV which may potentially be modified. 

Scenario: A CSV on-cluster owns a particular namespace-scoped CRD via its `OwnedCRDs` section and has cleanup enabled. It is installed into a namespace with an invalid OperatorGroup (either no OperatorGroup exists in the namespace, or multiple OperatorGroups exist) which results in an error and the CSV moves into a failed state. Since OLM looks at the relevant OperatorGroup when deciding in which namespaces to delete CRs in, an incorrect OperatorGroup configuration can inadverently effect cleanup. 

Solution: OLM does not allow automatic cleanup of CSVs that are in namespaces with incorrect OperatorGroup configurations. 

Scenario: A CSV A1 upgrades to A2 where A2 no longers owns the same APIs owned by A1. A1 and A2 are both connected nodes on an update graph in a catalog. Since OLM does not perform cleanup for CSVs in a `Replacing` phase, the CRs associated with the A1 APIs remain on-cluster. Deleting A2 after it successfully installs would not have a record of the APIs provided by A1, so although the A2 CRs would be cleanuped the existing A1 CRs would be orphaned on-cluster.

Solution: OLM accepts the possiblity of orphaned CRs in the case where operator upgrades in a graph introduce or deprecate APIs. 