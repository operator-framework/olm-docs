---
title: "Shipping an operator that supports Multiple Architectures"
linkTitle: "Multiarch Operators"
weight: 3
---

An operator's target OS and architecture can be specified by labelling its respective `ClusterServiceVersion`.

## Supported Labels

The following label convention defines the target OSes and architectures supported by an operator:

```yaml
labels:
    operatorframework.io/arch.<GOARCH>: supported
    operatorframework.io/os.<GOOS>: supported
```

Where `<GOARCH>` and `<GOOS>` are one of the values [listed here](https://github.com/golang/go/blob/master/src/go/build/syslist.go).

## Multiple Architectures

Some operators may support multiple node architectures or OSes. In this case, multiple labels can be added. For example, an operator that support both windows and linux workloads will sport the following labels:

```yaml
labels:
    operatorframework.io/os.windows: supported
    operatorframework.io/os.linux: supported
```

## Defaults

If a ClusterServiceVersion does not include an `os` label, a target OS is assumed to be `linux`.

```yaml
labels:
    operatorframework.io/os.linux: supported
```

If a ClusterServiceVersion does not include an `arch` label, a target architecture is assumed to be `amd64`.

```yaml
labels:
    operatorframework.io/arch.amd64: supported
```

## Filtering available operators by os or arch

Only windows:

```sh
kubectl get packagemanifests -l operatorframework.io/os.windows=supported
```

## Caveats

Only the labels on the [HEAD of the default channel](/docs/glossary/#channel-head) are considered for filtering PackageManifests by label.

This means, for example, that providing an alternate architecture for an operator in the non-default channel is possible, but will not be available for filtering in the PackageManifest API.
