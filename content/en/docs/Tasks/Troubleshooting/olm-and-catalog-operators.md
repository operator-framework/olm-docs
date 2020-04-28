---
title: "Debugging OLM and Catalog Operator"
linkTitle: "Debugging OLM/Catalog Operator"
date: 2020-03-25
weight: 5
description: >
  Tips and tricks related to debugging the OLM or Catalog Operator.
---

### How to enable verbose logging on the OLM and Catalog operators

Both the OLM and Catalog operators have `-debug` flags available that display much more useful information when diagnosing a problem. If necessary, add this flag to their deployments and perform the action that is showing undersired behavior.

### How to view the Catalog operator logs

To view the Catalog Operator logs, use the following commands:

```bash
$ kubectl -n olm get pods
NAME                                READY   STATUS    RESTARTS   AGE
catalog-operator-5bdc79c56b-zbqbl   1/1     Running   0          5m30s
olm-operator-6999db5767-5r5zs       1/1     Running   0          5m31s
operatorhubio-catalog-ltdlp         1/1     Running   0          5m28s
packageserver-5c76df75bb-mq4qd      1/1     Running   0          5m26s

$ kubectl -n olm logs catalog-operator-5bdc79c56b-zbqbl
...
```

### How to view the OLM operator logs

To view the OLM Operator logs, use the following commands:

```bash
$ kubectl -n olm get pods
NAME                                READY   STATUS    RESTARTS   AGE
catalog-operator-5bdc79c56b-zbqbl   1/1     Running   0          5m30s
olm-operator-6999db5767-5r5zs       1/1     Running   0          5m31s
operatorhubio-catalog-ltdlp         1/1     Running   0          5m28s
packageserver-5c76df75bb-mq4qd      1/1     Running   0          5m26s

$ kubectl -n olm logs olm-operator-6999db5767-5r5zs
...
```