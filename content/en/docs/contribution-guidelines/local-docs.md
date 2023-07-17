---
title: Build and serve the docs locally
linkTitle: Local Docs
---

## Prerequisites

For running local dev server you will only need to install stable version of [Go](https://go.dev/)
and clone the repository:

```bash
git clone https://github.com/operator-framework/olm-docs/
```

For other tasks such as building production version of the site
and linting you will also need to:
* Install Node.js LTS
* Install Docker or Podman


## Build and Serve

You can build and serve your docs to <http://localhost:1313/> with:

```bash
make serve
```

Any changes will be included in real time.

## Running the Linting Script Locally

To run linting locally you will need to run the following command:

```bash
make lint
```

This assumes `docker` command is available. If you want to specify different engine such as `podman`:

```bash
make lint CONTAINER_ENGINE=podman
```

Behind this target, the `hack/ci/link-check.sh` script is responsible for running [html-proofer](https://github.com/gjtorikian/html-proofer) that validates the generated HTML output.

**Note**: In the case you're getting permission denied errors when reading from that mounted volume, set the following environment variable and re-run the linting script:

```bash
make lint CONTAINER_RUN_EXTRA_OPTIONS="--security-opt label=disable"
```
