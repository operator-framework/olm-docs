---
title: "Creating operator manifests"
date: 2020-03-25
weight: 1
description: >
  Create operator manifests to describe your operator to OLM, i.e package your operator for OLM.
---

OLM requires you to provide metadata about your operator, so that the operator's lifecycle can be managed safely on a cluster. This section introduces you to the process of packaging the metadata in a format that is compatible with OLM.

This is very similar to packaging software for a traditional operating system - think of the packaging step for OLM as the stage at which you make your rpm, dep, or apk bundle.

## Writing your Operator Manifests

OLM uses a CRD called `ClusterServiceVersion` (CSV) to describe a single instance of a version of an operator. This is the main entry point for packaging an operator for OLM.

There are two important ways to think about the CSV:

1. Like an `rpm` or `deb`, it collects metadata about the operator that is required to install it onto the cluster.
2. Like a `Deployment` that can stamp out `Pod`s from a template, the `ClusterServiceVersion` describes a template for the operator `Deployment` and can stamp them out.

This is all in service of ensuring that when a user installs an operator from OLM, they can understand what changes are happening to the cluster, and OLM can ensure that installing the operator is a safe operation.

### Starting from an existing set of operator manifests

For this example, we'll use the example manifests from [the example memcached operator](https://github.com/operator-framework/operator-sdk-samples/tree/v0.19.2/go/memcached-operator/deploy).

These manifests consist of:

- **CRDs** that define the APIs your operator will manage.
- **Operator** (`operator.yaml`), containing the`Deployment` that runs your operator pods.
- **RBAC** (`role.yaml`, `role_binding.yaml`, `service_account.yaml`) that configures the service account permissions your operator requires.

Building a minimal `ClusterServiceVersion` from these manifests requires transplanting the contents of the Operator definition and the RBAC definitions into a CSV. Together, your CSV and CRDs will form the package that you give to OLM to install an operator.

#### Basic Metadata (Optional)

Let's start with a CSV that only contains some descriptive metadata:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  annotations:
  name: memcached-operator.v0.10.0
spec:
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
```

Most of these fields are optional, but they provide an opportunity to describe your operator to potential or current users.

#### Installation Metadata (Required)

The next section to add to the CSV is the Install Strategy - this tells OLM about the runtime components of your operator and their requirements.

Here is an example of the basic structure of an install strategy:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  annotations:
  name: memcached-operator.v0.10.0
spec:
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
```

`deployments` is an array - your operator may be composed of several seperate components that should all be deployed and versioned together.

It's also important to tell OLM the ways in which your operator can be deployed, or its `installModes`. InstallModes indicate if your operator can be configured to watch, one, some, or all namespaces. Please see the [document on operator scoping with operatorgroups][operatorgroups-docs] for more information.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  name: memcached-operator.v0.10.0
spec:
  # ...
  installModes:
  - supported: true
    type: OwnNamespace
  - supported: true
    type: SingleNamespace
  - supported: false
    type: MultiNamespace
  - supported: true
    type: AllNamespaces
```

**Using `faq` to build an install strategy from an existing deployment and rbac**

`faq` is a wrapper around `jq` that can handle multiple input and output formats, like the yaml we're working with now. The following example requires that [faq be installed](https://github.com/jzelinskie/faq#installation) and references [the example memcached operator](https://github.com/operator-framework/operator-sdk-samples/tree/v0.19.2/go/memcached-operator/deploy).

Here is a simple `faq` script that can generate an install strategy from a single deployment:

```sh
faq -f yaml  '{install: {strategy: "deployment", spec:{ deployments: [{name: .metadata.name, template: .spec }] }}}' operator.yaml
```

If you have an existing CSV `csv.yaml` (refer to the example from Basic Metadata) and you'd like to insert or update an install strategy from a deployment `operator.yaml`, a role `role.yaml`, and a service account `service_account.yaml`, that is also possible:

```sh
faq -f yaml -o yaml --slurp '.[0].spec.install = {strategy: "deployment", spec:{ deployments: [{name: .[1].metadata.name, template: .[1].spec }], permissions: [{serviceAccountName: .[3].metadata.name, rules: .[2].rules }]}} | .[0]' csv.yaml operator.yaml role.yaml service_account.yaml
```

#### Defining APIs (Required)

By definition, operators are programs that can talk to the Kubernetes API. Often, they are also programs that *extend* the Kubernetes API, by providing an interface via `CustomResourceDefinition`s or, less frequently, `APIService`s.

##### Owned APIs

Exactly which APIs are used and which APIs are watched or owned is important metadata for OLM. OLM uses this information to determine if dependencies are met and ensure that no two operators fight over the same resources in a cluster.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  name: memcached-operator.v0.10.0
spec:
  # ...
  customresourcedefinitions:
    owned:
    # a list of CRDs that this operator owns
    # name is the metadata.name of the CRD (which is of the form <plural>.<group>)
    - name: memcacheds.cache.example.com
      # version is the spec.versions[].name value defined in the CRD
      version: v1alpha1
      # kind is the CamelCased singular value defined in spec.names.kind of the CRD.
      kind: Memcached
```

##### Required APIs

Similarly, there is a section `spec.customresourcedefinitions.required`, where dependencies can be specified. The operators that provide those APIs will be discovered and installed by OLM if they have not been installed.

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  name: other-operator.v1.0
spec:
  # ...
  customresourcedefinitions:
    required:
    # a list of CRDs that this operator requires
    # name is the metadata.name of the CRD (which is of the form <plural>.<group>)
    - name: others.example.com
      # version is the spec.versions[].name value defined in the CRD
      version: v1alpha1
      # kind is the CamelCased singular value defined in spec.names.kind of the CRD.
      kind: Other
```

Dependency resolution and ownership is discussed more in depth in the [here][dependency-resolution-doc].

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  name: memcached-operator.v0.10.0
spec:
  # ...
  customresourcedefinitions:
    owned:
    # a list of CRDs that this operator owns
    # name is the metadata.name of the CRD (which is of the form <plural>.<group>)
    - name: memcacheds.cache.example.com
      # version is the spec.versions[].name value defined in the CRD
      version: v1alpha1
      # kind is the CamelCased singular value defined in spec.names.kind of the CRD.
      kind: Memcached
```

##### NativeAPIs (recommended)

There are often cases where you wish to depend on an API that is either provided natively by the platform (i.e. `Pod`) or sometimes by another operator that is outside the control of OLM.

In those cases, those dependencies can be described in the CSV as well, via `nativeAPIs`

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: ClusterServiceVersion
metadata:
  name: other-operator.v1.0
spec:
  nativeAPIs:
  - group: ""
    version: v1
    kind: Pod
```

The absence of any required `nativeAPIs` from a cluster will pause the installation of the operator, and `OLM` will write a status into the `CSV` indicating the missing APIs.

TODO: example status

`nativeAPIs` is an optional field, but the more information you give OLM about the context in which your operator should be run, the more informed decisions OLM can make.

## Packaging Additional Objects Alongside an Operator

Operators can include additional objects alongside their `CSV` in the `/manifests` directory. These objects should be YAML files and valid kubernetes objects. The following objects are supported as of OLM 0.16.0:

- ConfigMaps
- Secrets
- Services
- (Cluster)Role
- (Cluster)RoleBinding
- ServiceAccount
- PrometheusRule
- ServiceMonitor
- ConsoleYamlSample
- [PodDisruptionBudgets](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/adding-pod-disruption-budgets.md)
- [PriorityClasses](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/adding-priority-classes.md)
- [VerticalPodAutoscalers](https://github.com/operator-framework/operator-lifecycle-manager/blob/master/doc/design/adding-vertical-pod-autoscaler.md)

**Note**: some of these objects can affect an upgrade of the cluster and potentially cause problems for workloads unrelated to your operator. Be sure to understand the safe use of these objects before packaging them with your operator. See the docs linked above for more information on these objects as they relate to OLM.*

### Limitations on Pod Disruption Budgets

No limitations are placed on the contents of a PDB at this time when installing on-cluster.
However, the following are suggested guidelines to follow when including PDB objects in a bundle.

- maxUnavailable field cannot be set to 0 or 0%.
  - This can make a node impossible to drain and block important lifecycle actions like operator upgrades or even cluster upgrades.
- minAvailable field cannot be set to 100%.
  - This can make a node impossible to drain and block important lifecycle actions like operator upgrades or even cluster upgrades.

### Limitations on Priority Classes

No limitations are placed on the contents of a PriorityClass manifest at this time when installing on-cluster.
However, the following is a suggested guideline to follow when including PriorityClass objects in a bundle.

- globalDefault should always be false on a PriorityClass included in a bundle.
  - Setting globalDefault on a PriorityClass means that all pods in the cluster without an explicit priority class will use this default PriorityClass. This can unintentionally affect other pods running in the cluster.

#### Extension apiservers and APIServices

TODO: Document on extension apiservers for operators that do not rely on CRDs to provide its API.
#### Advanced and Optional features

TODO: Documentation for advanced operator configuration which includes additional suggestions for further integration with OLM.

### Operator SDK

You can also generate the manifests for your bundle using the `operator-sdk` binary. Checkout the documentation for generating CSV using `operator-sdk` [here][operator-sdk-csv-generation]. 


[operator-sdk-csv-generation]: https://sdk.operatorframework.io/docs/olm-integration/generation/
[api-repo]: https://github.com/operator-framework/api
[operatorgroups-docs]: /docs/advanced-tasks/operator-scoping-with-operatorgroups
[dependency-resolution-doc]: /docs/concepts/olm-architecture/dependency-resolution
