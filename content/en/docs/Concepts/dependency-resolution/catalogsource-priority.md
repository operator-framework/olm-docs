---
title: "CatalogSource Priority"
weight: 2
---

As part of the dependency resolver, OLM can choose from a wide range of catalogs to resolve dependencies including the ones in the same namespace as a Subscription plus any CatalogSources in the configurable global namespace. CatalogSource is a CR that defines where the catalog comes from and, therefore, can infer the amount of confidence cluster administrators or operator subscribers would want to rely on certain catalogs. OLM would like to explicitly sort catalogs for the dependency resolver so that certain catalogs can be prioritized.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: operatorhubio-catalog
  namespace: olm
spec:
  priority: 0
  sourceType: grpc
  image: quay.io/operatorhubio/catalog:latest
  displayName: Community Operators
  publisher: OperatorHub.io
```

Priority field, if specified, is used to rank CatalogSources that contain operators to supply dependencies and prioritize certain catalogs based on their rankings. The CatalogSource Priority for supplying dependencies has the following properties:
 - The higher the value, the higher the priority. 
 - The range of the priority value can go from positive to negative in the range of int32. 
 - The default value to a CatalogSource with unassigned priority would be 0. This means custom CatalogSource without assigning a priority will be prioritized before the default catalogs. 
 - The CatalogSources are sorted deterministically with the following rules in their order: 
    1. The CatalogSource of the installing operator.
    2. The CatalogSource carrying a higher `priority` integer value.
    3. The CatalogSource in the same namespace as the installing operator.
    4. Increasing lexicographic order of the CatalogSource name.

