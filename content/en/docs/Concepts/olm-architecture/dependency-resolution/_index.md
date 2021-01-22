---
title: "Dependency Resolution"
linkTitle: "Dependency Resolution"
date: 2020-09-18
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

 - **Properties** - typed metadata about the operator that constutes the public interface for it in the dependency resolver. Examples include the GVKs of the APIs provided by the operator and the SemVer version of the operator
 - **Constraints** or **Dependencies** - an operator's requirements that should be satisfied by other operators (that may or may not have already been installed) on the target cluster. These act as queries / filters over all available operators and constrain the selection when resolving or installing. Examples include requiring a specific API to be available on the cluster, or expecting a particular operator with a particular version to be installed.


Under the hood, these properties and constraints are converted into a system of boolean formulas and handed to a [SAT-solver](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem), which does the heavy lifting of determining what operators should be installed.

## Declaring Properties

Properties cannot be directly declared by an operator author. Instead, they are derived from the existing metadata provided in the CSV.

All operators in a catalog will have these properties:

 - `olm.package` - includes the name of the package and the version of the operator
 - `olm.gvk` - one property is present for each "provided" API from the ClusterServiceVersion

A future release of OLM will support explicit property creation.

## Declaring Dependencies

Dependencies are declared by including a `dependencies.yaml` file in the `metadata` directory of the operator bundle. For more information on bundles and the their format, see the [bundle docs](https://github.com/operator-framework/operator-registry/blob/master/docs/design/operator-bundle.md).

Currently, only two types of constraints are supported:

 - `olm.gvk` - declare a requirement on an API
 - `olm.package` - declare a requirement on a specific package / version range


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

***Note***: The `version` field above follows the [SemVer 2.0 Spec](https://semver.org/) for version ranges, and specifically uses [blang/semver](https://github.com/blang/semver) to parse.

The resolver sees these constraints as (assuming this is for `FooOperator v1.0.0`):

 - If `FooOperator v1.0.0` is picked, there must also be a an operator picked that provides `EtcdCluster`.
 - If `FooOperator v1.0.0` is picked, there must also be a an operator picked from `prometheus` package with version `>0.27.0`.

This looks (and is) straightforward, but it's worth looking at how this is handled at runtime in [Understanding Preferences](#understanding-preferences).

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
  image: example.com/my/operator-index:v1
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

Operators may add or remove APIs at any time - always specify an `olm.gvk` dependency on any APIs your operator requires. The exception to this is if you are specifying `olm.packageVersion` constraints instead. See [Caveats](#caveats) for more information.

### Set a minimum version

The Kubernetes [documentation on API changes](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api_changes.md#readme) describes what changes are allowed for kube-style operator APIs. These versioning conventions allow an operator to update an API without bumping the `apiVersion`, as long as the API is backwards-compatible.

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

Maximum versions can and should be set, however, if there are known incompatibilties that must be avoided. Note that specific versions can be omitted with the version range syntax, e.g. `> 1.0.0 !1.2.1`. 

## Caveats

These are some things to be cautious of when specifying dependencies.

### No compound constraints ("AND")

There is not a way to specify an "AND" relationship between constraints. In other words, there is no way to say: "this operator depends on another operator that both provides `Foo` api and has version `>1.1.0`".

This means that when specifying a dependency like this:

```yaml
dependencies:
- type: olm.package
  value:
    packageName: etcd
    version: ">3.1.0"
- type: olm.gvk
  value:
    group: etcd.database.coreos.com
    kind: EtcdCluster
    version: v1beta2
```

It would be possible for OLM to satisfy this with two operators: one that provides `EtcdCluster` and one that has version `>3.1.0`. Whether that happens, or whether an operator is selected that satisfies both constraints, depends on the ordering that potential options are visited. This [order is well-defined](#understanding-preferences) and can be reasoned about, but to be on the safe side, operators should stick to one mechanism or the other.

A future release of OLM will support compound constraints. When that happens, this guidance will change.

### Cross-Namespace Compatibility

OLM performs dependency resolution at the namespace scope. It is possible to get into an update deadlock if updating an operator in one namespace would be an issue for an operator in another namespace, and vice-versa. 

## Backwards-Compatibility Notes

`dependencies.yaml` is supported in `0.16.1+` versions of OLM.

In versions of OLM < `0.16.1`, only GVK constraints are supported, and only via the `required` section of the ClusterServiceVersion.
