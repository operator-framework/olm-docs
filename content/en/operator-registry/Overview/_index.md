---
title: "Overview"
linkTitle: "Overview"
weight: 1
description: >
    This page introduces you to Operator Registry and what you can achieve with it
---

{{% alert title="Warning" color="warning" %}}
These pages are under construction. TODO: Some of the sections below needs to be updated.
{{% /alert %}}


## What is Operator-Registry?

[Operator Registry](https://github.com/operator-framework/operator-registry) runs in a Kubernetes or OpenShift cluster to provide operator catalog data to [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager).


Operator Registry provides the following binaries:

 * `initializer`, which takes as an input a directory of operator manifests and outputs a sqlite database containing the same data for querying.
 * `registry-server`, which takes a sqlite database loaded with manifests, and exposes a gRPC interface to it.
 * `configmap-server`, which takes a kubeconfig and a configmap reference, and parses the configmap into the sqlite database before exposing it via the same interface as `registry-server`.
 
And libraries:
 
 * `pkg/client` - providing a high-level client interface for the gRPC api.
 * `pkg/api` - providing low-level client libraries for the gRPC interface exposed by `registry-server`.
 * `pkg/registry` - providing basic registry types like Packages, Channels, and Bundles.
 * `pkg/sqlite` - providing interfaces for building sqlite manifest databases from `ConfigMap`s or directories, and for querying an existing sqlite database.

## Why do I want Operator Registry?
Operator registry allows you to package your operator in a defined format and make it available for OLM so that it can install your operator in a 
kubernetes cluster

## Where should I go next?

Give your users next steps from the Overview. For example:

* [Getting Started](/operator-registry/getting-started/): Get started with project
* [Examples](/operator-registry/examples/): Check out some example code!