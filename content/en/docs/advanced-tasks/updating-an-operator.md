---
title: "Receiving updates to your installed operator"
weight: 2
description: >
  When an operator you installed has a newer version in the CatalogSource you installed it from, the CatalogSource needs to be updated to receive the new version of the operator in your cluster.  
---

For example, when an operator is installed from a catalog such as the [upstream-community-operators](https://quay.io/repository/operator-framework/upstream-community-operators) catalog that comes shipped with OLM, and there is a newer version of the operator in that catalog, the newer version of the operator can be made available on cluster by rebuilding the catalog.

I.e, you can get the updates to your operators by fetching the latest release of the catalog's container image.

If the image used to build the `Catalogsource` uses a versioned tag, update the tag version of the image to fetch updates to operators in the `Catalogsource`.

For example:

```
$ oc get catsrc operatorhubio-catalog -n olm -o yaml | grep image:
    
    image: quay.io/operator-framework/upstream-community-operators:0.0.1

$ kubectl patch catsrc operatorhubio-catalog -n olm --type=merge -p '{"spec": {"image": "quay.io/operator-framework/upstream-community-operators:0.0.2"}}'

```

If the image used to build the `Catalogsource` uses the `latest` tag, simply delete the pod corresponding to the `CatalogSource`. When the pod is recreated, it will be recreated with the latest image of the catalog, which will contain updates to the operators in that catalog.

For example:

```
$ kubectl delete pods -n olm -l olm.catalogSource=operatorhubio-catalog

```
The operators that were installed from the catalog will be updated automatically or manually, depending on the value of `installPlanApproval` in the Subscription for the operator. For more information on approving manual updates to operators, please read [this](/docs/concepts/crds/subscription#manually-approving-upgrades-via-subscriptions) section. 
