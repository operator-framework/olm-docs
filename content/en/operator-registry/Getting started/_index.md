---
title: "Getting Started"
linkTitle: "Getting Started"
date: 2020-03-25
weight: 2
description: >
    Package and deliver operator manifests to Kubernetes cluster using [Operator-Registry](https://github.com/operator-framework/operator-registry) 
---

{{% alert title="Warning" color="warning" %}}
These pages are under construction.
{{% /alert %}}


## Prerequisites

- [git](https://git-scm.com/downloads)
- [go](https://golang.org/dl/) version `v1.12+`.
- [docker](https://docs.docker.com/install/) version `17.03`+.
  - Alternatively [podman](https://github.com/containers/libpod/blob/master/install.md) `v1.2.0+` or [buildah](https://github.com/containers/buildah/blob/master/install.md) `v1.7+`
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) `v1.11.3+`.
- Access to a Kubernetes `v1.11.3+` cluster.

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
