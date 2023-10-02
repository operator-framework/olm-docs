---
title: "Configuring OLM"
linkTitle: "Configuring OLM"
weight: 3
---

## Configuring OLM

The [Operator-Lifecycle-Manager (OLM)](https://github.com/operator-framework/operator-lifecycle-manager) controller can be configured through an  [OLMConfig CustomResourceDefinition (CRD)](https://github.com/operator-framework/api/blob/v0.11.0/crds/operators.coreos.com_olmconfigs.yaml) named `cluster`. This document will outline what configurations OLM currently supports.

### Disabling Copied CSVs

#### Background

When an operator is installed by OLM, a stripped down copy of its CSV is created in every namespace the operator is configured to watch. These stripped down CSVs are known as "Copied CSVs" and communicate to users which controllers are actively reconciling resource events in a given namespace. When operators are installed in the AllNamespace mode, a Copied CSV is created in every namespace on the cluster. On especially large clusters, with namespaces and installed operators tending in the hundreds or thousands, Copied CSVs consume an untenable amount of resources; e.g. OLM's memory usage, cluster Etcd limits, networking, etc.

#### Usage

In an effort to support these larger cluster, OLM allows users to disable Copied CSVs for operators installed in the AllNamespace mode by setting the `cluster` olmConfig's `spec.features.disableCopiedCSVs` field to true.

```bash=
$ kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OLMConfig
metadata:
  name: cluster
spec:
  features:
    disableCopiedCSVs: true # Disabled Copied CSVs for AllNamespace operators.
EOF
olmconfig.operators.coreos.com/cluster configured
```

When Copied CSVs are Disabled, OLM will capture this information in an event in the operator's namespace, an example of the event can be seen below:

```bash=
$ kubectl get events 
LAST SEEN   TYPE      REASON               OBJECT                                MESSAGE
85s         Warning   DisabledCopiedCSVs   clusterserviceversion/my-csv.v1.0.0   CSV copying disabled for operators/my-csv.v1.0.0
```

When the `cluster` olmConfig's `spec.features.disableCopiedCSVs` field is missing or set to `false`, OLM will recreate the Copied CSVs for all operators installed in the AllNamespace mode and deleted the previously mentioned events. 

Additional information about this feature can be found in its original [enhancement proposal](https://github.com/operator-framework/enhancements/blob/master/enhancements/olm-toggle-copied-csvs.md).

### Changing the Package Server Sync Interval

#### Background

After CatalogSources are created, they are synced by the OLM packageservers every 12 hours. This sync interval may be increased to reduce the CPU utilization of the packageserver and CatalogSources, or decreased to improve response times to available updates. This field represents a duration, but is limited to using hours, minutes and seconds.

#### Usage

```bash=
$ kubectl apply -f - <<EOF
apiVersion: operators.coreos.com/v1
kind: OLMConfig
metadata:
  name: cluster
spec:
  features:
    packageServerSyncInterval: 1h30m
EOF
olmconfig.operators.coreos.com/cluster configured
```

When the `cluster` olmConfig's `spec.features.packageServerSyncInterval` field is missing, OLM will use the default value of `12h`.
