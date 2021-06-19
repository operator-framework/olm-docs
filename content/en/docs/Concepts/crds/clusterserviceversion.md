---
title: "ClusterServiceVersion"
weight: 2
---

A ClusterServiceVersion (CSV) represents a particular version a running operator on a cluster. It includes metadata such as name, description, version, repository link, labels, icon, etc. It declares `owned`/`required` CRDs, cluster requirements, and install strategy that tells OLM how to create required resources and set up the operator as a [deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

OLM requires you to provide metadata about your operator in order to ensure that it can be kept running safely on a cluster, and to provide information about how updates should be applied as you publish new versions of your operator.

This is very similar to packaging software for a traditional operating system - think of the packaging step for OLM as the stage at which you make your `rpm`, `deb`, or `apk` bundle.

## Writing your Operator Manifests

OLM uses an api called `ClusterServiceVersion` (CSV) to describe a single instance of a version of an operator. This is the main entrypoint for packaging an operator for OLM.

There are two important ways to think about the CSV:

1. Like an `rpm` or `deb`, it collects metadata about the operator that is required to install it onto the cluster.
2. Like a `Deployment` that can stamp out `Pod`s from a template, the `ClusterServiceVersion` describes a template for the operator `Deployment` and can stamp them out.

This is all in service of ensuring that when a user installs an operator from OLM, they can understand what changes are happening to the cluster, and OLM can ensure that installing the operator is a safe operation.

## Example ClusterServiceVersion

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  annotations:
  name: memcached-operator.v0.10.0
spec:
  # metadata
  description: This is an operator for memcached.
  displayName: Memcached Operator
  keywords:
  - memcached
  - app
  maintainers:
  - email: corp@example.com
    name: Some Corp
  maturity: alpha
  provider:
    name: Example
    url: www.example.com
  version: 0.10.0
  minKubeVersion: 1.16.0

  # operator scope
  installModes:
  - supported: true
    type: OwnNamespace
  - supported: true
    type: SingleNamespace
  - supported: false
    type: MultiNamespace
  - supported: true
    type: AllNamespaces

  # installation
  install:
    # strategy indicates what type of deployment artifacts are used
    strategy: deployment
    # spec for the deployment strategy is a list of deployment specs and required permissions - similar to a pod template used in a deployment
    spec:
      permissions:
      - serviceAccountName: memcached-operator
        rules:
        - apiGroups:
          - ""
          resources:
          - pods
          verbs:
          - '*'
          # the rest of the rules
      # permissions required at the cluster scope
      clusterPermissions:
      - serviceAccountName: memcached-operator
        rules:
        - apiGroups:
          - ""
          resources:
          - serviceaccounts
          verbs:
          - '*'
          # the rest of the rules
      deployments:
      - name: memcached-operator
        spec:
          replicas: 1
          # the rest of a deployment spec

  # apis provided by the operator
  customresourcedefinitions:
    owned:
    # a list of CRDs that this operator owns
    # name is the metadata.name of the CRD
    - name: cache.example.com
      # version is the version of the CRD (one per entry)
      version: v1alpha1
      # spec.names.kind from the CRD
      kind: Memcached
    required:
    # a list of CRDs that this operator requires
    - name: other.example.com
      version: v1alpha1
      kind: Other
```
