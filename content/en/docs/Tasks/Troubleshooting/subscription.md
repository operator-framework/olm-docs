---
title: "Subscription"
linkTitle: "Subscription"
date: 2020-03-25
weight: 3
description: >
  Tips and tricks related to troubleshooting the creation of a `Subscription`.
---

{{% pageinfo %}}
This section assumes that you have a working `CatalogSource`. Please see how to [troubleshoot a CatalogSource](/docs/tasks/troubleshooting/catalogsource/) if you're having trouble configuring a CatalogSource.
{{% /pageinfo %}}

### How to debug a failing Subscription

The Catalog operator will constantly update the `Status` of `Subscription` to reflect its current state. You can check the `Status` of your `Subscription` with the following command:

`$ kubectl -n my-namespace get subscriptions my-subscription -o yaml | yq r - status`

>Note: It is possible that the `Status` is missing, which suggests that the Catalog operator is encountering an issue when processing the `Subscription` in a very early stage.

If the `Status` block does not provide enough information, check the [Catalog operator's logs](/docs/tasks/troubleshooting/olm-and-catalog-operators/#how-to-view-the-catalog-operator-logs).

### A subscription in namespace X can't install operators from a CatalogSource in namespace Y

`Subscriptions` cannot install operators provided by `CatalogSources` that are not in the same namespace unless the `CatalogSource` is created in the `olm` namespace.

### Why does a single failing subscription cause all subscriptions in a namespace to fail?

Each Subscription in a namespace acts as a part of a set of operators for the namespace - think of a Subscription as an entry in a python `requirements.txt`. If OLM is unable to resolve part of the set, it knows that resolving the entire set will fail, so it will bail out of the installation of operators for that particular namespace. Subscriptions are separate objects but within a namespace they are all synced and resolved together.
