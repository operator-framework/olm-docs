---
title: "Opting into UnsafeFailForward upgrades"
linkTitle: "Opting into UnsafeFailForward upgrades"
weight: 4
description: >
  UnsafeFailForward upgrades is a feature that allows for the automatic upgrade of failed installs and upgrades. 
  It is ultimately unsafe and should only be used in specific circumstances. 
---

## Warning

This feature is not recommended in a majority of cases as enabling UnsafeFailForward upgrades no longer guarantees sane upgrade paths, possibly causing unrecoverable failures resulting in data loss. Only use this feature if you:

- Know every operator installed in the namespace.
- Have deep knowledge regarding the upgrade paths for each operator in the namespace.
- Have control over the contents of the catalogs providing the operators in the namespace.
- Do not want to manually upgrade your failed operators.

## What "UnsafeFailForward" upgrades add

A failed installation/upgrade is typically caused by one of two scenarios:

- **A Failed CSV:** The [CSV](https://olm.operatorframework.io/docs/concepts/crds/clusterserviceversion/) is in the FAILED phase.
- **A Failed InstallPlan:** Usually occurs because a resource listed in the [InstallPlan](https://olm.operatorframework.io/docs/concepts/crds/installplan/) fails to be created or updated. An InstallPlan may fail independently of its CSV and may fail to create the CSV.

By opting into "UnsafeFailForward" upgrades, OLM will allow you to recover from failed installations and upgrades by:
- Allowing CSVs to move from the FAILED phase to the REPLACING phase.
- Allowing OLM to calculate new InstallPlans for a set of installables if:
  - The InstallPlan referenced by a Subscription is in the FAILED phase.
  - The CatalogSource has been updated to include a new upgrade for one or more CSVs in the namespace.

## Using UnsafeFailForward Upgrades

Since resolution is namespace scoped, the toggle for allowing "UnsafeFailForward" upgrades is namespace scoped as well. Accordingly, the namespace scoped resource, OperatorGroup, has the `upgradeStrategy` field.

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: foo
  namespace: bar
spec:
  # Possible values include "Default" or "TechPreviewUnsafeFailForward".
  upgradeStrategy: TechPreviewUnsafeFailForward
```

With the upgradeStrategy type set to `TechPreviewUnsafeFailForward`, OLM will allow operators to "UnsafeFailForward" in adherence with the principles discussed below. If the upgradeStrategy is unset or set to `Default` OLM will exhibit existing behavior.

## Understanding "UnsafeFailForward" upgrades

Before using UnsafeFailForward upgrades, it is important to understand how OLM and the Resolver calculate what needs to be installed. When determining what to install, OLM provides the Resolver with the set of CSVs in a namespace. The Resolver treats these CSVs differently depending on whether or not they are claimed by a Subscription, where the Subscription lists the CSV's name in its `.status.currentCSV` field.
- If a CSV is claimed by a Subscription, the Resolver will allow it to be upgraded by a bundle that replaces it.
- If a CSV is not claimed by a Subscription, it is assumed that the user installed the CSV themselves, that OLM should not upgrade the CSV, and that it must appear in the next set of installables.

OLM's Resolver is deterministic, meaning that the set of installables will not change for a given set of arguments if no new upgrades have been declared in the existing CatalogSources. When an upgrade fails due to a CSV entering the FAILED phase, the CSV being replaced still exists and is not referenced by a Subscription. Today, OLM would send both `Operator v1` and `Operator v2` to the Resolver which will normally be unsatisfiable because `Operator v1` is marked as required and `Operator v2` cannot be upgraded further since it provides the same APIs as `Operator v1`. In order to support "failing forward", OLM needs to omit CSVs in the REPLACING phase from the set of arguments sent to the Resolver when "UnsafeFailForward" upgrades are enabled.

### When an InstallPlan failed

Let's review what steps must be taken to recover from a failed InstallPlan today:

- `Operator v1` is being upgraded to `Operator v2`.
- The InstallPlan for `Operator v2` fails.
- `Operator v3` is added to the catalog and is defined as the upgrade for `Operator v1`.
- The user deletes the InstallPlan created for `Operator v2`.
- A new InstallPlan is generated for `Operator v3` and the upgrade succeeds.

With "UnsafeFailForward" upgrades, OLM allows new InstallPlans to be generated if:
- The failed InstallPlan is referenced by a Subscription in the namespace.
- The CatalogSource has been updated to include a new upgrade for the set of arguments.

In practice, the fourth step from the previous workflow would be removed, meaning that the you simply need to update the CatalogSource and wait for the cluster to move past the failed install. With catalog polling enabled, you can even skip updating the CatalogSource directly by pushing a new catalog image to the same tag.

> BEST PRACTICE NOTE: If a bundle is known to fail, it should be skipped in the upgrade graph using the [skips](https://olm.operatorframework.io/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/#skips) or [skipRange](https://olm.operatorframework.io/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/#skiprange) feature.

To further understand, let's visualize this.

{{<mermaid>}}
graph TD;
    A(Operavtor V1 installed) --> B(Starts upgrading to Operator V2)

    B --> |Install succeeds| F(Operator V2 is installed and succeeds)

    B --> |InstallPlan fails| C(Operator V3 added to catalog replacing V2)
    C --> |Upgrade blocked as V1 is in solution set still| D(Manually delete Operator V2 InstallPlan)
    D --> |New InstallPlan generated and approved| E(Operator V3 is installed and succeeds)

    B --> |InstallPlan fails with UnsafeFailForward upgrades| H(Operator V3 added to catalog replacing V2)
    H --> |New InstallPlan generated and approved| J(Operator V3 is installed and succeeds)
{{</mermaid>}}

### When one or more CSVs have failed

Let's review what steps must be taken to recover from a failed CSV today:

- `Operator v1` is being upgraded to `Operator v2`.
- The CSV for `Operator v2` enters the FAILED phase.
- `Operator v3` is added to the catalog which replaces or skips `Operator v2`.
- The Resolver cannot upgrade `Operator v2` while including `Operator v1` in the solution set, upgrade is blocked.
- User manually deletes the existing CSVs, a new InstallPlan is generated and approved.
- `Operator v3` is installed and the upgrade succeeds.

To further understand, let's visualize this.

{{<mermaid>}}
graph TD;
  A(Operator V1 installed) --> B(Starts upgrading to Operator V2)

  B --> |Install succeeds| F(Operator V2 is installed and succeeds)

  B --> |CSV enters FAILED phase| C(Operator V3 added to catalog replacing V2)
  C --> |Upgrade blocked as V1 is in solution set still| D(Manually delete Operator V2 CSV)
  D --> |New InstallPlan generated and approved| E(Operator V3 is installed and succeeds)

  B --> |CSV enters FAILED phase with UnsafeFailForward upgrades| H(Operator V3 added to catalog replacing V2)
  H --> |New InstallPlan generated and approved| J(Operator V3 is installed and succeeds)
{{</mermaid>}}

When you opt into "UnsafeFailForward" upgrades, OLM:
- Does not include CSVs in the REPLACING phase in the set of arguments sent to the Resolver if the final CSV in the upgrade chain is in the FAILED phase and all other CSVs are in the REPLACING phase.
- Allows CSVs to move from the FAILED phase to the REPLACING phase.

These changes allow OLM to recover from any number of failed CSVs in an upgrade path, replacing the latest FAILED CSV with the next upgrade.
