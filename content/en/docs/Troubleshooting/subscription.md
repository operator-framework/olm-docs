---
title: "Subscription"
linkTitle: "Subscription"
date: 2020-03-25
weight: 3
description: >
  Tips and tricks related to troubleshooting the creation of a `Subscription`.
---

{{% pageinfo %}}
This section assumes that you have a working `CatalogSource`. Please see how to [troubleshoot a CatalogSource](/docs/troubleshooting/catalogsource/) if you're having trouble configuring a CatalogSource.
{{% /pageinfo %}}

## Prerequisites

- [yq](https://github.com/mikefarah/yq)

### How to debug a failing Subscription

The Catalog operator will constantly update the `Status` of `Subscription` to reflect its current state. You can check the `Status` of your `Subscription` with the following command:

`$ kubectl get subscription <subscription-name> -n <namespace> -o yaml | yq e '.status' -`

>Note: It is possible that the `Status` is missing, which suggests that the Catalog operator is encountering an issue when processing the `Subscription` in a very early stage.

If the `Status` block does not provide enough information, check the [Catalog operator's logs](/docs/troubleshooting/olm-and-catalog-operators/#how-to-view-the-catalog-operator-logs).

### A subscription in namespace X can't install operators from a CatalogSource in namespace Y

`Subscriptions` cannot install operators provided by `CatalogSources` that are not in the same namespace unless the `CatalogSource` is created in the `olm` namespace.

### A subscription fails because I deleted a similar subscription and left the CSV it installed

By creating a `Subscription`, the user is "subscribing" to updates from a particular package and channel within a `CatalogSource`. When a `ClusterServiceVersion (CSV)` is created to fulfill the `Subscription`, the `Subscription` is updated so it is "associated" with that `CSV`. "Associated" `CSVs` do not need to appear in the solution set allowing the `Subscription`'s' requirements to be met by `CSVs` in the channel that are valid upgrades from the existing `CSV`.

When you delete a `Subscription`, the `CSV` is no longer "associated" with any `Subscriptions`. `CSVs` that are not "associated" with a `Subscription` must appear in the solution set returned by the resolver. Historically, this allowed users to "pin" a specific version of the operator and cancel any upgrades. 

Once a `CSV` is no longer "associated" with a `Subscription`, creating a new `Subscription` that subscribes to the same package and channel within a `CatalogSource` will not "associate" the existing `CSV` with the `Subscription` because there is no guarantee that the package, channel, and `CatalogSource` defined in the `Subscription` are globally unique.

Creating a new `Subscription` for the existing `CSV` causes the resolver to fail because of the following requirements:
- The `Subscription` requires an `CSV` that fulfills it.
- The existing `CSV` must appear in the solution set (remember, it cannot fulfill the requirements of `Subscriptions` it is not associated with).

This ultimately surfaces a resolution failure in the `Subscription's status.Conditions` array:
```bash
message: 'constraints not satisfiable: @existing/namespace-foo/operator-foo.v1.0.0
and catalogSource-foo/namespace-foo/4.Y/operator-foo.v1.1.0
originate from package foo-operator, subscription subscription-foo
requires catalogSource-foo/namespace-foo/4.Y/operator-foo.v1.1.0,
subscription subscription-foo exists, clusterserviceversion
operator-foo.v1.0.0 exists and is not referenced by a subscription'
reason: ConstraintsNotSatisfiable
status: "True"
type: ResolutionFailed
```

There are two potential workarounds:
- If you want to upgrade the operator, you will need to delete the existing `CSV`.
- If you do not want to upgrade the operator, you will need to delete the `Subscription`.

### Why does a single failing subscription cause all subscriptions in a namespace to fail?

Each Subscription in a namespace acts as a part of a set of operators for the namespace - think of a Subscription as an entry in a python `requirements.txt`. If OLM is unable to resolve part of the set, it knows that resolving the entire set will fail, so it will bail out of the installation of operators for that particular namespace. Subscriptions are separate objects but within a namespace they are all synced and resolved together.

### Subscription fails due to missing APIs

Newer versions of Kubernetes may deprecate and remove certain APIs that OLM supports. For example, the `apiextensions.k8s.io/v1beta1` GroupVersion is no longer available on Kubernetes 1.22+ clusters. Operators that rely on v1beta1 CRDs will fail to install on 1.22+ clusters, since the v1beta API has been removed. See
[the official Kubernetes deprecation guide](https://kubernetes.io/docs/reference/using-api/deprecation-guide/) for the full list of resources that have been deprecated and removed by individual Kubernetes versions. These APIs will continue to be available on older versions of Kubernetes and OLM will continue to support them moving forward.

In the case where a subscription is created to an operator that relies on missing APIs, for example a v1beta1 CRD, an error condition will be present on the subscription status with the following message:

```
api-server resource not found installing CustomResourceDefinition my-crd-name: GroupVersionKind apiextensions.k8s.io/v1beta1, Kind=CustomResourceDefinition not found on the cluster. This API may have been deprecated and removed, see https://kubernetes.io/docs/reference/using-api/deprecation-guide/ for more information.
```

This error indicates that the API apiextensions.k8s.io/v1beta1, Kind=CustomResourceDefinition is not available on-cluster. It indicates this particular GVK is not present on the api-server, which will happen on Kubernetes 1.22+ with deprecated built-in types like v1beta1 CRDs or v1beta1 RBAC.

This error can also arise when installing operator bundles with CustomResources that OLM supports, such as `VerticalPodAutoscalers` and `PrometheusRules`, but the relevant CustomResourceDefinition has not yet been installed. In this case, this error should eventually resolve itself provided the required CustomResourceDefinition gets installed on the cluster and is accepted by the api-server.

### Subscriptions failing due to unpacking errors

If a subscription that references an operator bundle fails to unpack successfully, the subscription fails with the following message:

```
bundle unpacking failed. Reason: DeadlineExceeded, and Message: Job was active longer than the specified deadline
```

There are many potential causes for bundle unpacking errors. Some of the most common causes include:
- Unreachable Operator bundle image
   - Misconfigured network, such as an incorrectly configured proxy/firewall
   - Missing operator bundle images from the reachable image registries
   - Invalid or missing image registry credentials/secrets
   - Image registry rate limits
- Resource limitations on the cluster
   - CPU or network limitations preventing operator bundle images from being pulled within the timeout (10 minutes)
   - Inability to schedule pods for unpacking operator bundle images
   - etcd performance issues

To resolve the error, address the underlying causes for the unpack failure. Next, delete any failing unpack jobs and their owner configMaps to force the subscription to retry unpacking the operator bundles.

To enable automated cleanup and retry of failed unpack jobs in a namespace, set the `operatorframework.io/bundle-unpack-min-retry-interval` annotation on the operatorGroup in the desired namespace. This annotation indicates the time after the last unpack failure when the unpack may be attempted again. Do not set this annotation to an interval shorter than `5m` to avoid unnecessary load on the cluster.

```
kubectl annotate operatorgroup <OPERATOR_GROUP> operatorframework.io/bundle-unpack-min-retry-interval=10m
```

This annotation does not enforce limits on the number of times an operator bundle may be unpacked on failure, preserving only 5 failing unpack attempts for inspection. Unless the underlying cause for the failure is addressed, this may cause OLM to attempt to unsuccessfully unpack the operator bundle indefinitely. Removing the annotation from the operatorGroup disables automated retries for failed unpacking jobs on that namespace.

With older versions of OLM, an installPlan might be generated for the failing subscription. To refresh a failed subscription with an InstallPlan, you must perform the following steps:

  1. Back up the subscription.
  2. Delete the failing installPlan, CSV, and subscription.
  3. Delete the failing unpack job and its owner configMap.
  4. Reapply the subscription.
