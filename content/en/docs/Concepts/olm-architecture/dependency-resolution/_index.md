---
title: "Dependency Resolution"
linkTitle: "Dependency Resolution"
date: 2022-01-31
weight: 12
---

Much like system or language package managers, OLM can resolve dependencies to fulfill an operator's runtime requirements.

A typical example is an operator that requires the use of some other Operator's APIs:

{{<mermaid>}}
graph TD;
    e(FooOperator) --> |Provides|ec(Kind: Foo<br/>apiVerson: foogroup.io/foo/v1alpha1);
    v(BarOperator) --> |Provides|vs(Kind: Bar<br/>apiVersion: bargroup.io/bar/v1alpha1);
    s(BazOperator) --> |Provides|ss(Kind: Baz<br />apiVersion: bazgroup.io/baz/v1alpha1)
    v--> |Requires|ec;

    classDef foo fill:#8addf2,stroke:#333,stroke-width:4px;
    classDef bar fill:#ffcc26,stroke:#333,stroke-width:4px;
    classDef baz fill:#ff7452,stroke:#333,stroke-width:4px;

    class e,ec foo;
    class v,vs bar;
    class s,ss baz;

    linkStyle default fill:none,stroke-width:2px;
{{</mermaid>}}

Installing `BarOperator` with OLM will automatically install `FooOperator` as well - assuming there are no other conflicts.

This is made possible with two types of data:

- **Properties** - typed metadata about the operator that constitutes the public interface for it in the dependency resolver. Examples include the GVKs of the APIs provided by the operator and the SemVer version of the operator
- **Constraints** or **Dependencies** - an operator's requirements that should be satisfied by other operators (that may or may not have already been installed) on the target cluster. These act as queries / filters over all available operators and constrain the selection when resolving or installing. Examples include requiring a specific API to be available on the cluster, or expecting a particular operator with a particular version to be installed.

Under the hood, these properties and constraints are converted into a system of boolean formulas and handed to a [SAT-solver](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem), which does the heavy lifting of determining what operators should be installed.

## Declaring Properties

All operators in a catalog will have these properties:

- `olm.package` - includes the name of the package and the version of the operator
- `olm.gvk` - one property is present for each "provided" API from the ClusterServiceVersion

Additional properties can also be directly declared by an operator author by including a `properties.yaml` file in the `metadata` directory of the operator bundle. See [Arbitrary Properties](#arbitrary-properties) for more information.

```yaml
properties:
- type: olm.kubeversion
  value:
    version: "1.16.0"
```

## Arbitrary Properties

Operator authors may declare arbitrary properties in `properties.yaml` file in the bundle metadata. These properties are translated into a map data structure that will be used as an input to the OLM resolver at runtime. However, these properties are opaque to the resolver as it doesn't understand the properties but it can evaluate the generic constraints against those properties to determine if the constraints can be satisfied given the properties list.

For example:
```yaml
properties:
  - property:
      type: sushi
      value: salmon
  - property:
      type: soup
      value: miso
  - property:
      type: olm.gvk
      value:
        group: olm.coreos.io
        version: v1alpha1
        kind: bento
```

This structure can be used to construct a CEL expression for generic constraint. See [Generic Constraint](#generic-constraint) for more information.

Note: `properties.yaml` is supported in `1.17.4+` versions of OPM.

## Declaring Dependencies

Required dependencies are statically defined in the operator bundle one of two ways:
- `dependencies.yaml` file
- `properties.yaml` file (supported by `1.17.4+ versions of OPM)

Each of these files can be included in the `metadata` directory of the operator bundle. For more information on bundles and the their format, see the [bundle docs](https://github.com/operator-framework/operator-registry/blob/master/docs/design/operator-bundle.md).

Currently, these types of constraints are supported in the `dependencies.yaml` file:

- `olm.gvk` - declare a requirement on an API <!-- TODO: add deprecation notice, indicate olm.constraint should be used -->
- `olm.package` - declare a requirement on a specific package / version range <!-- TODO: add deprecation notice, indicate olm.constraint should be used -->
- `olm.constraint` - declare a generic constraint on arbitrary operator properties (See [Generic Constraint](#generic-constraint) for more information)

Here's an example of a `dependencies.yaml`:

```yaml
dependencies:
- type: olm.package
  value:
    packageName: prometheus
    version: ">0.27.0"
- type: olm.gvk
  value:
    group: etcd.database.coreos.com
    kind: EtcdCluster
    version: v1beta2
```

Currently, these types of constraints are supported in the `properties.yaml` file:

- `olm.gvk.required` - declare a requirement on an API <!-- TODO: add deprecation notice, indicate olm.constraint should be used -->
- `olm.package.required` - declare a requirement on a specific package / version range <!-- TODO: add deprecation notice, indicate olm.constraint should be used -->
- `olm.constraint` - declare a generic constraint on arbitrary operator properties (See [Generic Constraint](#generic-constraint) for more information)

Here's an example of a `properties.yaml`:

```yaml
properties:
- type: olm.package.required
  value:
    packageName: prometheus
    versionRange: ">0.27.0"
- type: olm.gvk.required
  value:
    group: etcd.database.coreos.com
    kind: EtcdCluster
    version: v1beta2
```

***Note***: The `version` field above follows the [SemVer 2.0 Spec](https://semver.org/) for version ranges, and specifically uses [blang/semver](https://github.com/blang/semver) to parse.

The resolver sees these constraints as (assuming this is for `FooOperator v1.0.0`):

- If `FooOperator v1.0.0` is picked, there must also be a an operator picked that provides `EtcdCluster`.
- If `FooOperator v1.0.0` is picked, there must also be a an operator picked from `prometheus` package with version `>0.27.0`.

This looks (and is) straightforward, but it's worth looking at how this is handled at runtime in [Understanding Preferences](#understanding-preferences).

### Generic Constraint

An `olm.constraint` property declares a dependency constraint of a particular type, differentiating non-constraint and constraint properties. Its `value` field is an object containing a `failureMessage` field holding a string-representation of the constraint message that will be surfaced to the users if the constraint is not satisfiable at runtime, and as an informative comment for readers, and exactly one of the following keys that denotes the constraint type:

- `gvk`: type whose `value` and interpretation is identical to `olm.gvk`.
- `package`: type whose `value` and interpretation is identical to `olm.package`.
- `cel`: a [Common Expression Language (CEL)](https://github.com/google/cel-go) expression evaluated at runtime by OLM's resolver over arbitrary bundle properties and cluster information ([enhancement][cel-ep]).
- `all`, `any`, `not`: conjunction, disjunction, and negation constraints, respectively, containing one or more concrete constraints, ex. `gvk`, or a nested compound constraint ([enhancement][compound-ep]).

#### Common Expression Language (CEL)

The `cel` struct is specific to CEL constraint type that supports CEL as the expression language. The `cel` struct has `rule` field which contains the CEL expression string that will be evaluated against operator properties at the runtime to determine if the operator satisfies the constraint.

For example:
```yaml
type: olm.constraint
value:
  failureMessage: 'require to have "certified"'
  cel:
    rule: 'properties.exists(p, p.type == "certified")'
```

The CEL syntax supports a wide range of operators including logic operator such as `AND` and `OR`. As a result, a single CEL expression can have multiple rules for multiple conditions that are linked together by logic operators. These rules are evaluated against a dataset of multiple different properties from a bundle or any given source and the output is solved into a single bundle or operator that satisfies all of those rules within a single constraint.

For example:
```yaml
type: olm.constraint
value:
  failureMessage: 'require to have "certified" and "stable" properties'
  cel:
    rule: 'properties.exists(p, p.type == "certified") && properties.exists(p, p.type == "stable")'
```

#### Compound Constraint (`all`, `any`, `not`)

These [compound constraint][compound-ep] types are evaluated following their logical definitions.

This is an example of a conjunctive constraint (`all`) of two packages and one GVK,
i.e. they must all be satisfied by installed bundles:

```yaml
schema: olm.bundle
name: baz.v1.0.0
properties:
- type: olm.constraint
  value:
    failureMessage: All are required for Baz because...
    all:
      constraints:
      - failureMessage: Package bar is needed for...
        package:
          packageName: bar
          versionRange: '>=1.0.0'
      - failureMessage: GVK Buf/v1 is needed for...
        gvk:
          group: bufs.example.com
          version: v1
          kind: Buf
```

This is an example of a disjunctive constraint (`any`) of three versions of the same GVK,
i.e. at least one must be satisfied by installed bundles:

```yaml
schema: olm.bundle
name: baz.v1.0.0
properties:
- type: olm.constraint
  value:
    failureMessage: Any are required for Baz because...
    any:
      constraints:
      - gvk:
          group: foos.example.com
          version: v1beta1
          kind: Foo
      - gvk:
          group: foos.example.com
          version: v1beta2
          kind: Foo
      - gvk:
          group: foos.example.com
          version: v1
          kind: Foo
```

This is an example of a negation constraint (`not`) of one version of a GVK,
i.e. this GVK cannot be provided by any bundle in the result set:

```yaml
schema: olm.bundle
name: baz.v1.0.0
properties:
- type: olm.constraint
  value:
  all:
    constraints:
    - failureMessage: Package bar is needed for...
      package:
        packageName: bar
        versionRange: '>=1.0.0'
    - failureMessage: Cannot be required for Baz because...
      not:
        constraints:
        - gvk:
            group: foos.example.com
            version: v1alpha1
            kind: Foo
```

Negation is worth further explanation, since at first glance its semantics
are unclear in this context. The negation is really instructing the resolver
to remove any possible solution that includes a particular GVK, package
at a version, or satisfies some child compound constraint from the result set.
As a corollary, the `not` compound constraint should only be used within `all` or `any`,
since negating without first selecting a possible set of dependencies does not make sense.

##### Nested compound constraints

A nested compound constraint, one that contains at least one child compound constraint
along with zero or more simple constraints, is evaluated from the bottom up following
the procedures described for each above.

This is an example of a disjunction of conjunctions, where one, the other, or both
can be satisfy the constraint.

```yaml
schema: olm.bundle
name: baz.v1.0.0
properties:
- type: olm.constraint
  value:
    failureMessage: Required for Baz because...
    any:
      constraints:
      - all:
          constraints:
          - package:
              packageName: foo
              versionRange: '>=1.0.0'
          - gvk:
              group: foos.example.com
              version: v1
              kind: Foo
      - all:
          constraints:
          - package:
              packageName: foo
              versionRange: '<1.0.0'
          - gvk:
              group: foos.example.com
              version: v1beta1
              kind: Foo
```

The maximum raw size of an `olm.constraint` is 64KB to limit resource exhaustion attacks.
See [this issue][json-limit-issue] for details on why size is limited and not depth.
This limit can be changed at a later date if necessary.

[cel-ep]:https://github.com/operator-framework/enhancements/blob/master/enhancements/generic-constraints.md
[compound-ep]:https://github.com/operator-framework/enhancements/blob/master/enhancements/compound-bundle-constraints.md
[json-limit-issue]:https://github.com/golang/go/issues/31789#issuecomment-538134396

## Understanding Preferences

Often, there will be many options that equally satisfy a dependency. The dependency resolver will make choices about which one best fits the requirements of the requested operators - but as an operator author or a user, it can be important to understand how choices are made so that dependency resolution is unsurprising.

### Catalog Priority

On cluster, OLM reads `CatalogSource`s to know what operators are available for installation.

```yaml
apiVersion: "operators.coreos.com/v1alpha1"
kind: "CatalogSource"
metadata:
  name: "my-operators"
  namespace: "operators"
spec:
  sourceType: grpc
  image: example.com/my-namespace/cool-catalog:v1
  displayName: "My Operators"
  priority: 100
```

`CatalogSource` has a `priority` field, which is used by the resolver to know how to prefer options for a dependency.

There are two rules that govern catalog preference:

- Options in higher-priority catalogs are preferred to options in lower-priority catalogs
- Options in the same catalog as the depender are preferred to any other catalogs.

#### Example - Same catalog preferred to all others

{{<mermaid>}}
graph TD
    subgraph Catalog A - Priority 0
    e(FooOperator<br /><br />Provides: Foo)
    v(BarOperator<br /><br />Provides: Bar<br />Requires: Foo)
    end

    subgraph Catalog B - Priority 50
        e2(FooOperatorAlt<br /><br />Provides: Foo)
    end

    classDef foo fill:#8addf2,stroke:#333,stroke-width:4px;
    classDef fooSelected fill:#8addf2,stroke:green,stroke-width:4px;
    classDef bar fill:#ffcc26,stroke:#333,stroke-width:4px;
    classDef baz fill:#ff7452,stroke:#333,stroke-width:4px;

    class e fooSelected;
    class e2 foo;
    class v,vs bar;

    linkStyle default fill:none,stroke-width:2px;
{{</mermaid>}}

Installing `BarOperator` will install `FooOperator`, not `FooOperatorAlt`, even though `FooOperatorAlt` is in a catalog with higher priority

#### Example - Higher priority is preferred

{{<mermaid>}}
graph TD
    subgraph Catalog A - Priority 0
      v(BarOperator<br /><br />Provides: Bar<br />Requires: Foo)
    end

    subgraph Catalog B - Priority 50
        e2(FooOperator<br /><br />Provides: Foo)
    end

    subgraph Catalog C - Priority 100
        e3(FooOperatorAlt<br /><br />Provides: Foo)
    end

    classDef foo fill:#8addf2,stroke:#333,stroke-width:4px;
    classDef fooSelected fill:#8addf2,stroke:green,stroke-width:4px;
    classDef bar fill:#ffcc26,stroke:#333,stroke-width:4px;
    classDef baz fill:#ff7452,stroke:#333,stroke-width:4px;

    class e3 fooSelected;
    class e2 foo;
    class v,vs bar;

    linkStyle default fill:none,stroke-width:2px;
{{</mermaid>}}

Installing `BarOperator` will install `FooOperatorAlt`, not `FooOperator`.

### Channel Ordering

An operator package in a catalog is a collection of update channels that a user can subscribe to in a cluster. Channels may be used to provide a particular stream of updates for a minor release (i.e. `1.2`, `1.3`) or a simple release frequency (`stable`, `fast`).

It is likely that a dependency may be satisfied by operators in the same package, but different channels. For example, `version 1.2` of an operator may exist in both `stable` and `fast`.

Each package has a default channel, which is always preferred to non-default channels. If no option in the default channel can satisfy a dependency, options are considered from the remaining channels in lexicographic order of the channel name.

A future release of OLM will allow customizing the sort preference for channels.

### Ordering within a Channel

There are almost always multiple options to satisfy a dependency within a single channel - most operators in one package and channel provide the same set of APIs, for example.

When a user creates a subscription, they indicate which channel to recieve updates from - this immediately reduces the search to just that one channel. But within the channel, it is likely that many operators satsify a dependency.

Within a channel, "newer" operators are preferred - that is, operators that are higher up in the update graph. If the head of a channel satisfies a dependency, it will be tried first.

### Other Constraints

In addition to the constraints supplied by package dependencies, OLM adds a couple of extra constraints to represent the desired user state and enforce resolution invariants.

#### Subscription constraint

Subscriptions are user-supplied constraints for the resolver. They declare the intent to either install a new operator if it is not already on the cluster, or to keep an existing operator updated.

Much in the same way a dependency constraint filters the set of operators that can be installed to satisfy a dependency, a subscription constraint filters the set of operators that can satisfy a subscription.

##### Example - New Operator

In this example, all operators highlighted in green are options to satisfy the subscription constraint, because no operator has yet been installed.

{{<mermaid>}}
graph TD

    subgraph Cluster
      s(Subscription<br /><br />package: foo<br />channel: stable)
    end

    subgraph Catalog
        stable(package: foo<br />channel: stable) --> e2
        e2(FooOperator v1.2.3)
        e3(FooOperator v1.2.2)
        e4(FooOperator v1.2.1)
        e5(FooOperator v1.2.0)
        e6(FooOperator v1.1.0)
        e2 --> e3
        e3 --> e4
        e3 --> e5
        e4 --> e5
        e5 --> e6
    end

    classDef foo fill:#8addf2,stroke:#333,stroke-width:4px;
    classDef fooSelected fill:#8addf2,stroke:green,stroke-width:4px;
    classDef bar fill:#ffcc26,stroke:#333,stroke-width:4px;
    classDef baz fill:#ff7452,stroke:#333,stroke-width:4px;

    class s foo;
    class e2,e3,e4,e5,e6 fooSelected;
    class e2 foo;
    class v,vs bar;

    linkStyle default fill:none,stroke-width:2px;
{{</mermaid>}}

##### Example - Operator Updates

In this example, only operators that can update from the currently installed operator are options for the subscription constraint.

{{<mermaid>}}
graph TD

    subgraph Cluster
      s(Subscription<br /><br />package: foo<br />channel: stable)
      o(ClusterServiceVersion<br /><br />FooOperator v1.2.0)
    end

    subgraph Catalog
        stable(package: foo<br />channel: stable) --> e2
        e2(FooOperator v1.2.3)
        e3(FooOperator v1.2.2)
        e4(FooOperator v1.2.1)
        e5(FooOperator v1.2.0)
        e6(FooOperator v1.1.0)
        e2 --> e3
        e3 --> e4
        e3 --> e5
        e4 --> e5
        e5 --> e6
    end

    classDef foo fill:#8addf2,stroke:#333,stroke-width:4px;
    classDef fooSelected fill:#8addf2,stroke:green,stroke-width:4px;
    classDef bar fill:#ffcc26,stroke:#333,stroke-width:4px;
    classDef baz fill:#ff7452,stroke:#333,stroke-width:4px;

    class s,o foo;
    class e3,e4 fooSelected;
    class v,vs bar;

    linkStyle default fill:none,stroke-width:2px;
{{</mermaid>}}

Like dependencies, subscription constraints have preference as well. OLM will choose the newest (closest to the head of the channel) operator that satisfies the subscription constraint. In this example, `FooOperator v1.2.2` would be chosen first.

#### Package constraint

Within a namespace, no two operators may come from the same package.

## Best Practices

### Either depend on APIs or a specific version range of operators

Operators may add or remove APIs at any time - always specify an `olm.gvk` dependency on any APIs your operator requires. The exception to this is if you are specifying `olm.package` constraints instead. See [Caveats](#caveats) for more information.

### Set a minimum version

The Kubernetes [documentation on API changes](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api_changes.md) describes what changes are allowed for kube-style operator APIs. These versioning conventions allow an operator to update an API without bumping the `apiVersion`, as long as the API is backwards-compatible.

For operator dependencies, this means that knowing the `apiVersion` of a dependency may not be enough to ensure the dependent operator works as intended.

For example:

- `FooOperator v1.0` provides `v1alpha1` of `Foo`
- `FooOperator v1.0.1` adds a new field `spec.bar` to `Foo`, but still at `v1alpha1`

Your operator may require the ability to write `spec.bar` into `Foo`. An `olm.gvk` constraint alone is not enough for OLM to determine that you need `FooOperator v1.0.1` and not `FooOperator v1.0`.

Whenever possible, if a specific operator that provides an API is known ahead of time, specify an additional `olm.package` constraint to set a minimum.

### Omit a maximum version, or allow a very wide range

Because operators provide cluster-scoped resources (APIServices, CRDs), an operator that specifies a small window for a dependency may unnecessarily constrain updates for other consumers of that dependency.

A maximum version should not be set whenever possible, or should be set to a very wide semantic range (i.e. `>1.0.0 <2.0.0`) to prevent conflicts with other operators.

Unlike with conventional package managers, operator authors explicitly encode that updates are safe via OLM's channels. If an update is available for an existing subscription, it comes with the operator provider's promise that it can update from the previous version. Setting a maximum version for a dependency overrides the dependency author's update stream by unnecessarily truncating it at a particular upper bound.

Maximum versions can and should be set, however, if there are known incompatibilities that must be avoided. Note that specific versions can be omitted with the version range syntax, e.g. `> 1.0.0 !1.2.1`.

## Caveats

These are some things to be cautious of when specifying dependencies.

### Cross-Namespace Compatibility

OLM performs dependency resolution at the namespace scope. It is possible to get into an update deadlock if updating an operator in one namespace would be an issue for an operator in another namespace, and vice-versa.

## Backwards-Compatibility Notes

`dependencies.yaml` is supported in `0.16.1+` versions of OLM and `1.10.0+` versions of OPM.

In versions of OLM < `0.16.1`, only GVK constraints are supported, and only via the `required` section of the ClusterServiceVersion.

`properties.yaml` is supported in `1.17.4+` versions of OPM.
