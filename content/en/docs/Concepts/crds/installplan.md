---
title: "InstallPlan"
weight: 5
---

{{% alert title="Warning" color="warning" %}}
This section is under construction.
{{% /alert %}}

An InstallPlan defines a set of resources to be created in order to install or upgrade to a specific version of a ClusterService defined by a CSV.


InstallPlan can be created in two ways: 
1. Users can also create an InstallPlan resource directly, containing the names of the desired ClusterServiceVersions and an approval strategy.
2. When the Catalog Operator find a new InstallPlan, even though it likely created it, it will create an "execution plan" and embed that into the InstallPlan to create all of the required resources. Once approved, whether manually or automatically, the Catalog Operator will implement its portion of the the execution plan, satisfying the underlying expectations of the OLM Operator.

**_Table 1. Install plan phases_**

| Phase              | Description                                                                                 |
|--------------------|---------------------------------------------------------------------------------------------|
| None               | initial phase, once seen by the Operator, it is immediately transitioned to `Planning`      |
| Planning           | dependencies between resources are being resolved, to be stored in the InstallPlan `Status` |
| RequiresApproval   | occurs when using manual approval, will not transition phase until `approved` field is true |
| Installing         | resolved resources in the InstallPlan `Status` block are being created                      |
| Complete           | all resolved resources in the `Status` block exist                                          |
---------------------