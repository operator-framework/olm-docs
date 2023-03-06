---
title: "Uninstall your operator"
date: 2020-03-25
weight: 7
description: >
    Uninstall your operator from the cluster
---

When uninstalling an operator managed by OLM, a Cluster Admin must decide whether or not to remove the CustomResourceDefinitions (CRD), APIServices, and resources related to these types owned by the operator. By design, when OLM uninstalls an operator it does not remove any of the operator's owned CRDs, APIServices, or CRs in order to prevent data loss. Instead, it is left to the Cluster Admin to remove any unwanted types and resources from the cluster. This document will discuss the steps a Cluster Admin should take when uninstalling an operator.

## Step 1: Identifying Resources to Remove

The cluster admin should first understand which types (CRDs and APIServices) are owned by the operator, which is available in the operator's ClusterServiceVersion (CSV) under the `spec.customresourcedefinitions.owned` and `spec.apiservicedefinitions.owned` arrays. It is likely that users have created resources for these types since the operator was installed. The cluster admin should should decide which of these resources to delete on a case-by-case basis. If the resource is not required, delete it. The Cluster Admin should delete all unwanted resources before moving to the next step.

> Note: Although deleting the CRD or APIService removes all resource of the type from the cluster, this action may lead to unintended consequences. Operators often use [finalizers](https://book.kubebuilder.io/reference/using-finalizers.html) to execute application specific cleanup routines before removing the CR. If the API is removed, the operator will be unable to properly remove the resource, and the cluster may appear to be "stuck" as defined in this [Kubernetes issue](https://github.com/kubernetes/kubernetes/issues/60807).

## Step 2: Unsubscribe from the Operator

OLM uses the subscription resource to convey a user's intent to subscribe to the latest version of an operator. If the operator was installed with Automatic Updates (spec.InstallPlanApproval: `Automatic`), OLM will reinstall a new version of the operator even if the operator's CSV was deleted earlier. In effect, you must tell OLM that you do not want new versions of the operator to be installed by deleting the subscription associated with the operator.

You can list existing `Subscription` in a specific namespace with the following `kubectl` command:

```bash
$ kubectl get subscription -n <namespace>
# Example output
NAME                                                 PACKAGE              SOURCE            CHANNEL
foo-sub                                              foo                  foo-catalog       alpha
```

> Note: The name of the operator installed by the subscription is available under the `Package` column.

The `Subscription` can be deleted by running this command:

```bash
kubectl delete subscription <subscription-name> -n <namespace>
```

## Step 3: Delete the Operator's ClusterServiceVersion (CSV)

The CSV contains all the information that OLM needs to manage an operator, and it effectively represents an operator that is installed on cluster. By deleting a `ClusterServiceVersion`, OLM will delete the resources it created for the operator such as the deployment, RBAC, and any corresponding CSVs that OLM "Copied" into other namespaces watched by the operator.

If you wish to look up a list of `ClusterServiceVersion` in a specific namespace to see which `ClusterServiceVersion` you need to delete, you can use the example `kubectl` command:

```bash
$ kubectl get clusterserviceversion -n <namespace>
# Example output
NAME                        DISPLAY              VERSION   REPLACES                    PHASE
foo                         Foo Operator         1.0.0                                 Succeeded
```

You can delete the `ClusterServiceVersion` in the namespace that the operator was installed into using this command:

```bash
kubectl delete clusterserviceversion <csv-name> -n <namespace>
```

### Combine steps 2 and 3

Alternatively, you can delete both `Subscription` and its `CSV` using a sequence of commands:

```bash
CSV=$(kubectl get subscription <subscription-name> -n <namespace> -o json | jq -r '.status.installedCSV')
kubectl delete subscription <subscription-name> -n <namespace>
kubectl delete csv $CSV -n <namespace>
```

## Step 4: Deciding whether or not to delete the CRDs and APIServices

The final step consists of deciding whether or not to delete the CRDs and APIServices that were introduced to the cluster by the operator. Assuming you have already deleted all unwanted resources on cluster as enumerated in Step 1, if no resources remain it is safe to remove the CRD or APISerivces. Otherwise, you should not delete the type as the wanted resources will be deleted automatically when the CRD or APISerivce is deleted.
