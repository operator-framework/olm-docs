---
title: "Uninstall OLM"
date: 2020-03-25
weight: 9
description: >
    Uninstall OLM from your cluster
---

The process of uninstalling OLM is symmetrical to the process of installing it. Specifically all OLM specific [CRDs](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/deploy/upstream/quickstart/crds.yaml) and [the OLM deployment](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/deploy/upstream/quickstart/olm.yaml) need to be deleted. The `apiservices` should be removed as the first step, preventing it from becoming a dangling resource. 

>Note that uninstalling OLM does not necessarily clean up the operators installed with it. Please clean up installed operator resources before uninstalling OLM, especially for resources that do not have an owner reference.

## Uninstall Released OLM

For uninstalling released versions of OLM, you can use the following commands:

```bash
export OLM_RELEASE=<olm-release-version>
kubectl delete apiservices.apiregistration.k8s.io v1.packages.operators.coreos.com
kubectl delete -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${OLM_RELEASE}/crds.yaml
kubectl delete -f https://github.com/operator-framework/operator-lifecycle-manager/releases/download/${OLM_RELEASE}/olm.yaml
```

> NOTE: You can identify which version of OLM you are using by inspecting the version of the packageserver CSV.

> ```bash
> export OLM_NAMESPACE=<olm-namespace>
> kubectl -n $OLM_NAMESPACE get csvs
> NAME          DISPLAY        VERSION REPLACES PHASE
> packageserver Package Server 0.13.0           Succeeded
> ```

## Verify OLM Uninstall

You can check that OLM has been uninstalled by inspecting the OLM namespace.

```bash
kubectl get namespace $OLM_NAMESPACE
Error from server (NotFound): namespaces "$OLM_NAMESPACE" not found
```

More specifically, you can verify that OLM has been uninstalled successfully by making sure that OLM **owned** `CustomResourceDefinitions` are removed:

```bash
kubectl get crd | grep operators.coreos.com
```

You can also check that the OLM `deployments` are terminated:

```bash
kubectl get deploy -n $OLM_NAMESPACE
No resources found.
```

Lastly, check that the `role` and `rolebinding` in the OLM namespace are removed:

```bash
kubectl get role -n $OLM_NAMESPACE
No resources found.
```

```bash
kubectl get rolebinding -n $OLM_NAMESPACE
No resources found.
```
