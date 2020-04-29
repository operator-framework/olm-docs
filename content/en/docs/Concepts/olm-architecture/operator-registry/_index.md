
---
title: "Operator Registry"
weight: 3
---

{{% alert title="Warning" color="warning" %}}
These pages are under construction.
{{% /alert %}}

## What is Operator-Registry?
  
[Operator Registry](https://github.com/operator-framework/operator-registry) runs in a Kubernetes cluster to provide operator catalog data to [Operator Lifecycle Manager](https://github.com/operator-framework/operator-lifecycle-manager).

<pre></pre>
Operator Registry provides the following binaries:
 
 * `opm`, which generates and updates registry databases as well as the index images that encapsulate them.
 * `initializer`, which takes as an input a directory of operator manifests and outputs a sqlite database containing the same data for querying.
 * `registry-server`, which takes a sqlite database loaded with manifests, and exposes a gRPC interface to it.
 * `configmap-server`, which takes a kubeconfig and a configmap reference, and parses the configmap into the sqlite database before exposing it via the same interface as `registry-server`.
 <pre></pre>
And libraries:
  
 * `pkg/client` - providing a high-level client interface for the gRPC api.
 * `pkg/api` - providing low-level client libraries for the gRPC interface exposed by `registry-server`.
 * `pkg/registry` - providing basic registry types like Packages, Channels, and Bundles.
 * `pkg/sqlite` - providing interfaces for building sqlite manifest databases from `ConfigMap`s or directories, and for querying an existing sqlite database.
 * `pkg/lib` - providing external interfaces for interacting with this project as an api that defines a set of standards for operator bundles and indexes.
 * `pkg/containertools` - providing an interface to interact with and shell out to common container tooling binaries (if installed on the environment)
  
## Why do I want Operator Registry?
Operator registry allows you to package your operator in a defined format and make it available for OLM so that it can install your operator in a 
kubernetes cluster.
<pre></pre>   
You can find all the releases of operator-registry in the [github release page](https://github.com/operator-framework/operator-registry/releases)

## Installation

1. Clone the operator registry repository:

```bash
$ git clone https://github.com/operator-framework/operator-registry
```

2. Build the binaries using this command:

```bash
$ make all
```

This generates the required binaries that can be used to package your operator