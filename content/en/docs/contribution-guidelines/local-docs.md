---
title: Build and serve the docs locally
linkTitle: Local Docs
---

## Prerequisites

Clone the repository:

```bash
$ git clone https://github.com/operator-framework/olm-docs/
```

The docs are built with [Hugo](https://gohugo.io/) which can be installed along with the
required extensions by following the [docsy install
guide](https://www.docsy.dev/docs/getting-started/#prerequisites-and-installation).

We use `git submodules` to install the docsy theme. From the
root directory, update the submodules to install the theme.

```bash
$ git submodule update --init --recursive
```

## Build and Serve

You can build and serve your docs to localhost:1313 with:

```bash
$ hugo server
```

Any changes will be included in real time.
