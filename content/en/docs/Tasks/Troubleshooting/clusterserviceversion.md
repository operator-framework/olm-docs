---
title: "ClusterServiceVersion"
linkTitle: "ClusterServiceVersion"
date: 2020-03-25
weight: 4
description: >
  Tips and tricks related to troubleshooting a `ClusterServiceVersion`.
---

### How to debug a failing CSV

If the OLM operator encounters an unrecoverable error when attempting to install the operator, the `CSV` will be placed in the `failed` phase. The OLM operator will constantly update the `Status` with useful information regarding the state of the `CSV`. You can check the `Status` of your `CSV` with the following command:

```shell script
$ kubectl -n my-catalogsource-namespace get csv prometheusoperator.0.32.0 -o yaml | yq r - status
```

>Note: It is possible that the Status is missing, which suggests that the OLM operator is encountering an issue when processing the `CSV` in a very early stage. You should respond by reviewing the logs of the OLM operator.

You should typically pay special attention to the information within the `status.reason` and `status.message` fields. Please look in the [failed CSV reasons](#failed-csv-reasons)

If the `Status` block does not provide enough information, check the [OLM operator's logs](/docs/tasks/troubleshooting/olm-and-catalog-operators/#how-to-view-the-olm-operator-logs).

### Failed CSV Reasons

#### Reason: NoOperatorGroup

The `CSV` failed to install because it has been deployed in a namespace that does not include an [OperatorGroup](/docs/concepts/crds/operatorgroup/).

#### Reason: UnsupportedOperatorGroup

The `CSV` is failing to install because it does not support the [OperatorGroup](/docs/concepts/crds/operatorgroup/) defined in the namespace.

### Failed CSV Messages

#### Messages Ending with "field is immutable"

The `CSV` is failing because its install strategy changes some immutable field of an existing `Deployment`. This usually happens on upgrade, after an operator author publishes a new version of the operator containing such a change. In this case, the issue can be resolved by publishing a new version of the operator that uses a different `Deployment` name, which will cause OLM to generate a completely new `Deployment` instead of attempting to patch any existing one.