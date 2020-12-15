---
title: "Creating an udpate graph with OLM"
date: 2020-12-14
weight: 7
description: >
    Creating an udpate graph with OLM 
---

# Creating an Update Graph

OLM provides a variety of ways to specify updates between operator versions as well as different add
modes (requires bundle format) to control how versions fit into the catalog.

## Methods for Specifying Updates

### Replaces

For explicit updates from one CSV to another, you can specify the CSV name to replace in your CSV as
such:

```yaml
metadata:
   name: myoperator.v1.0.1
spec:
   replaces: myoperator.v1.0.0
```

In order for `myoperator.v1.0.1` to be added to the catalog successfully, `myoperator.v1.0.0` needs to
be included in your manifests or have already been added to that catalog (in the case where packaging
is done in the bundle format).

An update sequence of bundles created via `replaces` will have updates step through each version in
the chain. For example, given

```txt
myoperator.v1.0.0 -> myoperator.v1.0.1 -> myoperator.v1.0.2
```

A subscription on `myoperator.v1.0.0` will update to `myoperator.v1.0.2` through `myoperator.v1.0.1`.

Installing from the UI today will always install the latest of a given channel. However, installing
specific versions is possible with this update graph by modifying the `startingCSV` field
of the subscription to point to the desired CSV name. Note that, in this case, the subscription will
need its `approval` field set to `Manual` to ensure that the subscription does not auto-update and
instead stays pinned to the specified version.

### Skips

In order to skip through certain updates you can specify a list of CSV names to be skipped as such:

```yaml
metadata:
   name: myoperator.v1.0.3
spec:
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

Skipped CSVs do not need to be present in a catalog or set of manifests prior to adding to a catalog.

### SkipRange

OLM also allows you to specify updates through version ranges in your CSV. This requires your CSVs
to define a version in their version field which must follow the [semver spec](https://semver.org/).
Internally, OLM uses the [blang/semver](https://github.com/blang/semver) go library.

```yaml
metadata:
   name: myoperator.v1.0.3
   annotations:
      olm.skipRange: ">=1.0.0 <1.0.3"
```

The version specifying the `olm.skipRange` will be presented as a direct (one hop) update to
any version from that package within that range. The versions in this range do not need to be in
the index in order for bundle addition to be successful. We recommend avoiding using unbound ranges
such as `<1.0.3`.

**Warning:** Adding a bundle that only specifies skipRange to a given channel will wipe out all
the previous content in that channel. This means directly installing past versions by editing
the `startingCSV` field of the subscription is not possible when using skiprange only.

The above warning means that skiprange by itself is useful for teams who are not interested in
supporting directly installing versions within a given range.

## Channel Guidelines

### Cross channel updates

Cross channel updates are not possible today in an automated way. In order for your subscription
to switch channels, the cluster admin must manually change the `channel` field in the subcription
object.

Changing this field does not always result in receiving updates from that channel. For that to
occur, updates paths must be available from the given version to versions in the new channel.

#### If using replaces

The CSV name currently installed must be in the `replaces` field of a CSV in the new channel.

#### If using skips

The CSV name currently installed must be in the `skips` field of a CSV in the new channel.

#### If using skipRange

The version currently installed must be in the `olm.skipRange` field of a CSV in the new channel.

## Add Modes

TODO