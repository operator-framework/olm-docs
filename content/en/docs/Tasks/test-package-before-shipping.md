---
title: "Test a package before shipping"
date: 2020-12-14
weight: 7
description: >
    Test a package before shipping
---


To test your Operator with OLM we make use of `operator-sdk <run|cleanup>` subcommands related to OLM deployment,
and assumes you are familiar with [OLM][https://github.com/operator-framework/operator-lifecycle-manager/], related terminology,
and have read the SDK-OLM integration [design proposal][https://github.com/operator-framework/operator-sdk/blob/master/proposals/sdk-integration-with-olm.md].

For testing your Operator with OLM, you first need to package your Operator and then run it in a cluster with OLM installed in it. There are two packing formats available:

#### Package Manifest Format

The Package Manifest Format for Operators is the legacy packaging format introduced by the Operator Framework. In this format, a version of an Operator is represented by a single cluster service version (CSV) and typically the custom resource definitions (CRDs) that define the owned APIs of the CSV, though additional objects may be included. All versions of the Operator are nested in a single directory

When loading package manifests into the Operator Registry database, the following requirements are validated:
- Every package has at least one channel.
- Every CSV pointed to by a channel in a package exists.
- Every version of an Operator has exactly one CSV.
- If a CSV owns a CRD, that CRD must exist in the directory of the Operator version.
- If a CSV replaces another, both the old and the new must exist in the package.


#### Bundle Format

The Bundle Format for Operators is a new packaging format introduced by the Operator Framework. To improve scalability and to better enable upstream users hosting their own catalogs, the Bundle Format specification simplifies the distribution of Operator metadata.

An Operator bundle represents a single version of an Operator. On-disk bundle manifests are containerized and shipped as a bundle image, which is a non-runnable container image that stores the Kubernetes manifests and Operator metadata. Storage and distribution of the bundle image is then managed using existing container tools like podman and docker and container registries such as Quay.

When loading manifests into the Operator Registry database, the following requirements are validated:
- The bundle must have at least one channel defined in the annotations.
- Every bundle has exactly one cluster service version (CSV).
- If a CSV owns a custom resource definition (CRD), that CRD must exist in the bundle.

You can find more details about [run bundle](https://sdk.operatorframework.io/docs/olm-integration/testing-deployment/#operator-sdk-run-bundle-command-overview) and [run packagemanifests](https://sdk.operatorframework.io/docs/olm-integration/testing-deployment/#operator-sdk-run-packagemanifests-command-overview) to understand the shared configurations and the anatomy of those commands.


For an Operator to be tested in OLM, they need to be in a proper [PackageManifest](https://github.com/operator-framework/operator-registry/tree/v1.5.3#manifest-format) or they need to be in a proper [Bundle](https://github.com/operator-framework/operator-registry/tree/v1.15.3#manifest-format) format. Once they are brought to the appropriate format, they need to be deployed in the cluster. We assume that [OLM installtion](https://sdk.operatorframework.io/docs/cli/operator-sdk_olm_install/) should be complete before we run the Operator for testing. Once your Operator is deployed and tested, we have to cleanup using [operator-sdk cleanup](https://sdk.operatorframework.io/docs/cli/operator-sdk_olm_install/).