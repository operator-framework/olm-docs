---
title: "Enabling Operator Cleanup"
linkTitle: "Enabling Operator Cleanup"
weight: 3
---

OLM lets operator users opt-in to the cleanup of their operator workloads, known as Custom Resources (CRs) or operands, when the operator is deleted. The CRs would be deleted upon the uninstallation of the operator by removing the operator CSV. When uninstalling an operator, OLM would delete all CRs managed by an operator so that the operator can be triggered to clean up all the resources associated with its CRs via Finalizers.

By design when OLM uninstalls an operator it does not remove any CRs reconciled by the operator in order to prevent data loss. The operator user is expected to manually delete the CRs that they've created. However, operators that do have cleanup logic implemented via Finalizers or garbage collection owner references benefit from an automatic cleanup of all their managed resources when the operator is uninstalled. This cleanup of CRs and resources would have to happen before the operator is removed so it can process the deletion events of its CRs.

To facilitate an operator's cleanup logic, OLM can optionally delete any CRs provided by an operator before removing it.

*Note: Operand cleanup does not involve deleting any other resources associated with the operator, such as its CRDs. Be sure to fully understand the consequences of enabling cleanup for your operator, as it can result in data loss.*  

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

