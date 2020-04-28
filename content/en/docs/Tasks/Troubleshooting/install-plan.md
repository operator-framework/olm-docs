---
title: "InstallPlan"
linkTitle: "InstallPlan"
date: 2020-03-25
weight: 4
description: >
  Tips and tricks related to troubleshooting a `InstallPlan`.
---


The primary way an InstallPlan can fail is by not resolving the resources needed to install a CSV.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: InstallPlan
metadata:
  name: olm-testing
spec:
  clusterServiceVersionNames:
  - etcdoperator.v0.7.2
  approval: Automatic
```

This installPlan will fail because `etcdoperator.v0.7.2` is not in a catalog. We can see this in its status:

```bash
$ kubectl get installplans olm-testing -o yaml
apiVersion: operators.coreos.com/v1alpha1
kind: InstallPlan
metadata:
  ... 
spec:
  approval: Automatic
  clusterServiceVersionNames:
  - etcdoperator.v0.7.2
status:
  catalogSources:
  - rh-operators
  conditions:
  - lastTransitionTime: 2018-01-22T16:05:09Z
    lastUpdateTime: 2018-01-22T16:06:59Z
    message: 'not found: ClusterServiceVersion etcdoperator.v0.7.2'
    reason: DependenciesConflict
    status: "False"
    type: Resolved
  phase: Planning
```

Error messages like this will displayed for any other inconsistency in the catalog. They can be resolved by either updating the catalog or choosing clusterservices that resolve correctly.