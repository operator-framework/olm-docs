---
title: "Creating an update graph with OLM"
date: 2020-12-14
weight: 7
description: >
    Creating an update graph with OLM
---

>Note: This document discusses creating an upgrade graph for your operator using plaintext files to store catalog metadata, which is the [latest feature][file-based-catalog-spec] of OLM catalogs. If you are looking to create an upgrade graph for your operator using the deprecated sqllite database format to store catalog metadata instead, please read the [v0.18.z version][v0.18.z-version] of this doc instead.

# Creating an Update Graph

OLM provides a variety of ways to specify updates between operator versions.

## Methods for Specifying Updates

All update graphs are defined in [file-based catalogs][file-based-catalog-spec] via `olm.channel` blobs. Each `olm.channel` defines the set of
bundles present in the channel and the update graph edges between each entry in the channel.

### Replaces

For explicit updates from one operator version to another, you can specify the operator name to replace in your channel entry as
such:

```yaml
---
schema: olm.channel
package: myoperator
channel: stable
entries:
  - name: myoperator.v1.0.1
    replaces: myoperator.v1.0.0
```

Note that it is not required for there to be an entry for `myoperator.v1.0.0` in the catalog as long as
other channel invariants (verified by [`opm validate`][opm-validate-cli]) still hold. Generally, this means that the tail of the channel's
`replaces` chain can replace a bundle that is not present in the catalog.

An update sequence of bundles created via `replaces` will have updates step through each version in
the chain. For example, given

```txt
myoperator.v1.0.0 -> myoperator.v1.0.1 -> myoperator.v1.0.2
```

A subscription on `myoperator.v1.0.0` will update to `myoperator.v1.0.2` through `myoperator.v1.0.1`.

Installing from the UI today will always install the latest of a given channel. However, installing
specific versions is possible with this update graph by modifying the `startingCSV` field
of the subscription to point to the desired operator name. Note that, in this case, the subscription will
need its `approval` field set to `Manual` to ensure that the subscription does not auto-update and
instead stays pinned to the specified version.

### Skips

In order to skip through certain updates, you can specify a list of operator names to be skipped. For example:

```yaml
---
schema: olm.channel
package: myoperator
channel: stable
entries:
  - name: myoperator.v1.0.3
    replaces: myoperator.v1.0.0
    skips:
      - myoperator.v1.0.1
      - myoperator.v1.0.2
```

Using the above graph, this will mean subscriptions on `myoperator.v1.0.0` can update directly to
`myoperator.v1.0.3` without going through `myoperator.v1.0.1` or `myoperator.v1.0.2`. Installs
that are already on `myoperator.v1.0.1` or `myoperator.v1.0.2` will still be able to update to
`myoperator.v1.0.3`.

This is particularly useful if `myoperator.v1.0.1` and `myoperator.v1.0.2` are affected by a CVE
or contain bugs.

Skipped operators do not need to be present in a catalog or set of manifests prior to adding to a catalog.

### SkipRange

OLM also allows you to specify updates through version ranges in your channel entry. This requires your CSVs
to define a version in their version field which must follow the [semver spec](https://semver.org/).
Internally, OLM uses the [blang/semver](https://github.com/blang/semver) go library.

```yaml
---
schema: olm.channel
package: myoperator
channel: stable
entries:
  - name: myoperator.v1.0.3
    skipRange: ">=1.0.0 <1.0.3"
```

The entry specifying the `skipRange` will be presented as a direct (one hop) update to
any version from that package within that range. The versions in this range do not need to be in
the catalog in order for bundle addition to be successful. We recommend avoiding using unbound ranges
such as `<1.0.3`.

SkipRange by itself is useful for teams who are not interested in supporting directly installing
versions within a given range or for whom consumers of the operator are always on the latest
version.

## Channel Guidelines

### Cross channel updates

Cross channel updates are not possible today in an automated way. In order for your subscription
to switch channels, the cluster admin must manually change the `channel` field in the subscription
object.

Changing this field does not always result in receiving updates from that channel. For that to
occur, updates paths must be available from the given version to versions in the new channel.

#### If using replaces

The CSV name currently installed must be in the `replaces` field of an entry in the new channel.

#### If using skips

The CSV name currently installed must be in the `skips` field of an entry in the new channel.

#### If using skipRange

The version currently installed must be in the `skipRange` field of an entry in the new channel.

## Channel Promotion

A popular channel strategy is to use `alpha`, `beta`, and `stable` channels, where every new bundle is added to `alpha`,
a subset of bundles from `alpha` are promoted to `beta`, and a further subset of bundles from `beta` are promoted to
`stable`.

An operator author wishing to employ the `alpha`/`beta`/`stable` channel strategy may have created and updated their
`olm.channel` blobs following the below scenario.

First, an operator author releases a few versions into the `alpha` channel, with a simple linear replaces chain.
```yaml
---
schema: olm.channel
package: myoperator
channel: alpha
entries:
  - name: myoperator.v0.1.0
  - name: myoperator.v0.2.0
    replaces: myoperator.v0.1.0
  - name: myoperator.v0.3.0
    replaces: myoperator.v0.2.0
```

Next, an operator author decides that `myoperator.v0.2.0` is a good candidate to promote to `beta`, so they add a new
`olm.channel` schema and include `myoperator.v0.2.0` as the first entry, taking care to preserve any upgrade edges from
`alpha` to enable users to switch from the `alpha` to the `beta` channel if they have `myoperator.v0.1.0` installed.

> NOTE: This bundle already exists in the catalog (the image was already built and pushed, and the catalog already contains
> an `olm.bundle` blob and an entry for it in the `alpha`  channel). The channel promotion step for `myoperator.v0.2.0`
> is to simply create a new `olm.channel` for the `beta` channel and include an entry for `myoperator.v0.2.0`.

```yaml
---
schema: olm.channel
package: myoperator
channel: alpha
entries:
  - name: myoperator.v0.1.0
  - name: myoperator.v0.2.0
    replaces: myoperator.v0.1.0
  - name: myoperator.v0.3.0
    replaces: myoperator.v0.2.0
---
schema: olm.channel
package: myoperator
channel: beta
entries:
  - name: myoperator.v0.2.0
    replaces: myoperator.v0.1.0
```

The operator continues releasing bundles to `alpha` and promotes `myoperator.v0.4.0`  to `beta`.

> NOTE: In channel `alpha`, `myoperator.v0.4.0` replaces `myoperator.v0.3.0`, but in channel `beta`, `myoperator.v0.4.0`
> replaces `myoperator.v0.2.0` because the `beta` channel does not include every entry from alpha.

```yaml
---
schema: olm.channel
package: myoperator
channel: alpha
entries:
  - name: myoperator.v0.1.0
  - name: myoperator.v0.2.0
    replaces: myoperator.v0.1.0
  - name: myoperator.v0.3.0
    replaces: myoperator.v0.2.0
  - name: myoperator.v0.4.0
    replaces: myoperator.v0.3.0
  - name: myoperator.v0.5.0
    replaces: myoperator.v0.4.0
---
schema: olm.channel
package: myoperator
channel: beta
entries:
  - name: myoperator.v0.2.0
    replaces: myoperator.v0.1.0
  - name: myoperator.v0.4.0
    replaces: myoperator.v0.2.0
```

Finally, the operator author releases several more bundles and makes several more promotions, finally deciding to
promote `myoperator.v0.4.0` to the stable channel. With `myoperator.v0.4.0` being the first entry in the `stable`
channel, the operator author has decided to add `replaces` and `skips` edges for all previously released bundles to
assist users in moving to the `stable` channel directly from the `alpha` and `beta` channels. However, it would have
been equally valid to require that a user have either `myoperator.v0.2.0` or `myoperator.v0.3.0` installed (e.g. if the
direct upgrade from `myoperator.v0.1.0` has not been tested or is known to be unsupported).

```yaml
---
schema: olm.channel
package: myoperator
channel: alpha
entries:
  - name: myoperator.v0.1.0
  - name: myoperator.v0.2.0
    replaces: myoperator.v0.1.0
  - name: myoperator.v0.3.0
    replaces: myoperator.v0.2.0
  - name: myoperator.v0.4.0
    replaces: myoperator.v0.3.0
  - name: myoperator.v0.5.0
    replaces: myoperator.v0.4.0
  - name: myoperator.v0.6.0
    replaces: myoperator.v0.5.0
---
schema: olm.channel
package: myoperator
channel: beta
entries:
  - name: myoperator.v0.2.0
    replaces: myoperator.v0.1.0
  - name: myoperator.v0.4.0
    replaces: myoperator.v0.2.0
  - name: myoperator.v0.6.0
    replaces: myoperator.v0.4.0
---
schema: olm.channel
package: myoperator
channel: stable
entries:
  - name: myoperator.v0.4.0
    replaces: myoperator.v0.1.0
    skips:
      - myoperator.v0.2.0
      - myoperator.v0.3.0
```

## Skip vs. SkipRange vs. Replaces by Example

For these examples we will be considering an operator that is already installed (`Installed`) and how update options are selected for it.

{{<mermaid>}}
graph LR;
  subgraph Update<br>Options
    a
    b
    c
  end
  I(Installed) 
  a -->|can update from| I
  b -->|can update from| I
  c -->|can update from| I
{{</mermaid>}}

Invariants to keep in mind:

- Anything in the channel that `replaces` the `Installed` package is an option.
- Anything in the channel that is `skipped` by anything else in the channel is **not** considered an option.
- Anything in the channel that has a `skipRange` that includes `Installed` is an option.

Once there's a set of options found, they're "tried" by the resolver in order. This try-order in is defined by their `depth` in the channel **as defined by replaces and skips only**. 

### Incremental update validation

When a new version is released, upgrades are tested from the latest release in the channel.

As QE / automation has time, updates are tested from older releases. Those extra edges will be added over time.

We'll assume a semver, kube-like versioning/update strategy.

#### By only adding Skips

---
`Installed` is at `v1`:

{{<mermaid>}}
graph LR;
  I(Installed - v1) 
{{</mermaid>}}
---
Release `v1.1` that `replaces` `v1`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v1.1
  end
  v1.1 -->|replaces| I
{{</mermaid>}}
---
Release `v1.2` that `replaces` `v1.1`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v1.1
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
{{</mermaid>}}
---
Test that `v1.2` can also update from `v1`. Add a `skips: v1` to `v1.2`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v1.2
    v1.1
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skips| I
{{</mermaid>}}

---
Release `v2` that `replaces` `v1.2`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v1.1
    v1.2
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skips| I
  v2 --> |replaces| v1.2
  
{{</mermaid>}}
---

Test that `v2` can also update from `v1.1` and `v1`. Add `skips: [v1, v1.1]`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v2
    v1.2
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skips| I
  v2 --> |replaces| v1.2
  v2 --> |skips| v1.1
  v2 --> |skips| I
{{</mermaid>}}

Note that `v1.1` is no longer an option for `v1` - it has been skipped by something else in the channel.

---

Release `v2.1` that replaces `v2`

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v2
    v1.2
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skips| I
  v2 --> |replaces| v1.2
  v2 --> |skips| v1.1
  v2 --> |skips| I
  v2.1 --> |replaces| v2
{{</mermaid>}}

---

Test that `v2.1` can also update from `v1.2`. Add `skips: [v1.2]`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v2
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skips| I
  v2 --> |replaces| v1.2
  v2 --> |skips| v1.1
  v2 --> |skips| I
  v2.1 --> |replaces| v2
  v2.1 --> |skips| v1.2
{{</mermaid>}}

---

Add a `v2.2` that `replaces` `v2.1` and `skips: [v2]`

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skips| I
  v2 --> |replaces| v1.2
  v2 --> |skips| v1.1
  v2 --> |skips| I
  v2.1 --> |replaces| v2
  v2.1 --> |skips| v1.2
  v2.2 --> |replaces| v2.1
  v2.2 --> |skips| v2
{{</mermaid>}}

Note that `v1` is now completely cut off from updates: there is no version with an edge to `v1` that is not `skipped` by something else.

#### By only adding SkipRange

---
`Installed` is at `v1`:

{{<mermaid>}}
graph LR;
  I(Installed - v1) 
{{</mermaid>}}
---
Release `v1.1` that `replaces` `v1`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v1.1
  end
  v1.1 -->|replaces| I
{{</mermaid>}}
---
Release `v1.2` that `replaces` `v1.1`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v1.1
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
{{</mermaid>}}
---
Test that `v1.2` can also update from `v1`. Add a `skipRange: v1` to `v1.2`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v1.2
    v1.1
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skipRange| I
{{</mermaid>}}
---
Release `v2` that `replaces` `v1.2`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v1.1
    v1.2
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skipRange| I
  v2 --> |replaces| v1.2
{{</mermaid>}}
---

Test that `v2` can also update from `v1.1` and `v1`. Add `skipRange: v1 v1.1`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v2
    v1.1
    v1.2
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skipRange| I
  v2 --> |replaces| v1.2
  v2 --> |skipRange| v1.1
  v2 --> |skipRange| I
{{</mermaid>}}

---

Release `v2.1` that replaces `v2`

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v2
    v1.2
    v1.1
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skipRange| I
  v2 --> |replaces| v1.2
  v2 --> |skipRange| v1.1
  v2 --> |skipRange| I
  v2.1 --> |replaces| v2
{{</mermaid>}}

---

Test that `v2.1` can also update from `v1.2`. Add `skipRange: v1.2`:

{{<mermaid>}}
graph LR;
  I(Installed - v1)
  subgraph Update<br>Options
    v2
    v1.2
    v1.1
  end
  v1.1 -->|replaces| I
  v1.2 -->|replaces| v1.1
  v1.2 -->|skipRange| I
  v2 --> |replaces| v1.2
  v2 --> |skipRange| v1.1
  v2 --> |skipRange| I
  v2.1 --> |replaces| v2
  v2.1 --> |skipRange| v1.2
{{</mermaid>}}

[file-based-catalog-spec]: /docs/reference/file-based-catalogs
[opm-validate-cli]: /docs/reference/file-based-catalogs/#opm-validate
[v0.18.z-version]:  https://v0-18-z.olm.operatorframework.io/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/