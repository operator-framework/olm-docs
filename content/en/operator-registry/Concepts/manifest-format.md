---
title: "Manifest Format"
linkTitle: "Manifest Format"
date: 2020-03-25
weight: 3
description: >
  This page describes the packaging format for your operator
---

{{% alert title="Warning" color="warning" %}}
These pages are under construction.
{{% /alert %}}


We refer to a directory of files with one ClusterServiceVersion as a "bundle". A bundle is typically just a ClusterServiceVersion and the CRDs that define the owned APIs of the CSV, though additional objects may be included.

```bash
 # example bundle
 0.6.1
 ├── etcdcluster.crd.yaml
 └── etcdoperator.clusterserviceversion.yaml
```

When loading manifests into the database, the following invariants are validated:

 * Every package has at least one channel
 * Every ClusterServiceVersion pointed to by a channel in a package exists
 * Every bundle has exactly one ClusterServiceVersion.
 * If a ClusterServiceVersion `owns` a CRD, that CRD must exist in the bundle.
 * If a ClusterServiceVersion `replaces` another, both the old and the new must exist in the package.

Bundle directories are identified solely by the fact that they contain a ClusterServiceVersion, which provides an amount of freedom for layout of manifests.

It's recommended to follow a layout that makes it clear which bundles are part of which package, as in manifest:

```bash
manifests
├── etcd
│   ├── 0.6.1
│   │   ├── etcdcluster.crd.yaml
│   │   └── etcdoperator.clusterserviceversion.yaml
│   ├── 0.9.0
│   │   ├── etcdbackup.crd.yaml
│   │   ├── etcdcluster.crd.yaml
│   │   ├── etcdoperator.v0.9.0.clusterserviceversion.yaml
│   │   └── etcdrestore.crd.yaml
│   ├── 0.9.2
│   │   ├── etcdbackup.crd.yaml
│   │   ├── etcdcluster.crd.yaml
│   │   ├── etcdoperator.v0.9.2.clusterserviceversion.yaml
│   │   └── etcdrestore.crd.yaml
│   └── etcd.package.yaml
└── prometheus
    ├── 0.14.0
    │   ├── alertmanager.crd.yaml
    │   ├── prometheus.crd.yaml
    │   ├── prometheusoperator.0.14.0.clusterserviceversion.yaml
    │   ├── prometheusrule.crd.yaml
    │   └── servicemonitor.crd.yaml
    ├── 0.15.0
    │   ├── alertmanager.crd.yaml
    │   ├── prometheus.crd.yaml
    │   ├── prometheusoperator.0.15.0.clusterserviceversion.yaml
    │   ├── prometheusrule.crd.yaml
    │   └── servicemonitor.crd.yaml
    ├── 0.22.2
    │   ├── alertmanager.crd.yaml
    │   ├── prometheus.crd.yaml
    │   ├── prometheusoperator.0.22.2.clusterserviceversion.yaml
    │   ├── prometheusrule.crd.yaml
    │   └── servicemonitor.crd.yaml
    └── prometheus.package.yaml
```
