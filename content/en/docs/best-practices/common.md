---
title: "Common recommendations and suggestions"
linkTitle: "Common suggestions"
weight: 2
description: Common recommendations and suggestions to distribute solutions with Operator OLM
---

## Overview

Any recommendation or good practice suggested by the Kubernetes community such as to develop [Operator pattern][operator-pattern] solutions or to manage them are good recommendations for who is looking for to build the operator projects and distribute them with OLM. Also, see [Operator Best Practices][operator-best-practices] and ensure that you check out [Running On-Cluster][running-on-cluster].

## Validate your bundle before publish it

Check and test your operator bundle before you publish it. Note that the [`operator-sdk`][operator-sdk] CLI can help with that process. You can validate a bundle via [`operator-sdk bundle validate`][sdk-cli-bundle-validate] against the entire suite of validators for Operator Framework, in addition to required bundle validators:

```sh
operator-sdk bundle validate ./bundle --select-optional suite=operatorframework
```

The `OperatorHub.io` validator in the `operatorframework` optional suite allows you to validate that your manifests can work with a Kubernetes cluster of a particular version using the `k8s-version` optional key value:

```sh 
operator-sdk bundle validate ./bundle --select-optional suite=operatorframework --optional-values=k8s-version=1.22
```

Also, you can validate a bundle via [`operator-sdk scorecard`][sdk-cli-scorecard-bundle] to insure it against a suite of tests:

```sh
operator-sdk scorecard bundle
```

## Provide what are the k8s versions supported by your project

In the [CSV](/docs/concepts/crds/clusterserviceversion) manifest of your operator bundle, you can set the `spec.minKubeVersion` property to inform what is the minimal Kubernetes version which your project supports: 

```yaml
  ...
    spec:
      maturity: alpha
      version: 0.4.0
      minKubeVersion: 1.16.0
```

It is recommended you provide this information. Otherwise, it would mean that your operator project can be distributed and installed in any cluster version available, which is not necessarily the case for all projects.

[operator-best-practices]: https://sdk.operatorframework.io/docs/best-practices/best-practices/
[operator-pattern]: https://kubernetes.io/docs/concepts/extend-kubernetes/operator/
[operator-sdk]: https://github.com/operator-framework/operator-sdk
[sdk-cli-bundle-validate]: https://sdk.operatorframework.io/docs/cli/operator-sdk_bundle_validate/ 
[sdk-cli-scorecard-bundle]: https://sdk.operatorframework.io/docs/cli/operator-sdk_scorecard/
[running-on-cluster]: https://master.sdk.operatorframework.io/docs/best-practices/best-practices/#running-on-cluster