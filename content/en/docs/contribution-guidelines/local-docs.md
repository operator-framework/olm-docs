---
title: Build and serve the docs locally
linkTitle: Local Docs
---

## Prerequisites

Clone the repository:

```bash
git clone https://github.com/operator-framework/olm-docs/
```

The docs are built with [Hugo](https://gohugo.io/) which can be installed along with the
required extensions by following the [docsy install
guide](https://www.docsy.dev/docs/getting-started/).

We use `git submodules` to install the docsy theme. From the
root directory, update the submodules to install the theme.

```bash
git submodule update --init --recursive
```

## Build and Serve

You can build and serve your docs to localhost:1313 with:

```bash
hugo server
```

Any changes will be included in real time.

## Running the Linting Script Locally

The `hack/ci/link-check.sh` script is responsible for building the site and running [html-proofer](https://github.com/gjtorikian/html-proofer) that validates the generated HTML output.

Before running the linting script, ensure you have the correct environment variable sets locally:

- `$CONTAINER_ENGINE`: controls what container engine will be used. Defaults to `docker`.
- `$CONTAINER_RUN_EXTRA_OPTIONS`: allows you to specify any additional run options to the container engine. Defaults to an empty string.

In order to run the linting script locally using `podman`, run the following command from the root directory:

```bash
export CONTAINER_ENGINE="podman"
${PWD}/hack/ci/link-check.sh
```

**Note**: In the case you're getting permission denied errors when reading from that mounted volume, set the following environment variable and re-run the linting script:

```bash
export CONTAINER_RUN_EXTRA_OPTIONS="--security-opt label=disable"
${PWD}/hack/ci/link-check.sh
```
