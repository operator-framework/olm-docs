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
