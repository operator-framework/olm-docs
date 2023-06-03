---
title: Channel Naming
linkTitle: Channel Naming
description: This guide shows OLM users how to use and choose naming conventions for channels to manage their operator upgrades. 
---

## CHANNELS

Operator Lifecycle Manager (OLM) provides a channel concept that allows you 
as the operator author a means to specify a set of update streams for your 
operator.

Operator authors deal with two key tasks associated with OLM channels, first, 
how to define a channel for your operator and then lastly how to interact 
with OLM to deploy your operator using channels.   

For each version of an operator you can specify a channel that it will belong 
to. Since there can be multiple versions of an operator within a channel, 
there is a notion of the latest version within a channel, or the channel head 
version.  It's the channel head that OLM will install for most subscriptions.  

There can also be multiple channels for a given operator package which is 
used to offer different support models (e.g. pre-release, production).  Here 
is a diagram that shows the relationship of operator versions to channels:

![Channel Naming Image](/docs/best-practices/images/channel-naming1.png)

In the diagram above you can see the following:
  
  - A catalog named “vendor:v4.6”, this catalog is built by a cluster administrator typically
  - There are 2 operator packages found in the catalog, myoperator and otheroperator.
  - The myoperator has 3 bundles (1.0.0, 1.0.1, 1.0.2).  Versions 1.0.0 and 1.0.1 are in multiple channels (fast, stable).  Whereas version 1.0.2 is only in the fast channel.
  - The otheroperator has 2 bundles specifying 2 different channels (candidate, stable).  Version 1.4.0 specifies it is within 2 channels, stable and candidate.


Here is the view of another catalog, “vendor:v4.7”, that shows you can change 
the upgrade path for an operator by what operator bundles are contained 
within the catalog:

![Channel Naming Image](/docs/best-practices/images/channel-naming2.png)

### Defining Channels

Operator authors define the channels they intend to use by creating labels within their operator bundle.  Bundles  contain metadata about a particular operator version.  For example, when you build an operator bundle, you specify an annotations.yaml manifest which gets included into the bundle image.  Here is an example  snippet of an annotations.yaml file including channel information for that operator:

```
annotations:
  operators.operatorframework.io.bundle.channels.v1: candidate
  operators.operatorframework.io.bundle.channel.default.v1: candidate
  operators.operatorframework.io.bundle.manifests.v1: manifests/
  operators.operatorframework.io.bundle.mediatype.v1: registry+v1
  operators.operatorframework.io.bundle.metadata.v1: metadata/
  operators.operatorframework.io.bundle.package.v1: otheroperator
```

This example shows that you are defining the candidate channel to be used for 
this operator bundle.  Operator bundles are loaded into an Operator Index 
image using the opm command.  It is important to note that by specifying a 
channel value like this, you are essentially creating a channel which can 
then be subscribed to.  If you mis-type the channel name, there is nothing 
that validates the channel value because the channel is known by whatever 
you provide.

Note that you can specify a default channel for a given operator package. This 
default channel is used when an operator is being installed to fulfill 
a dependency requirement of another operator.  The dependent operator will 
be installed from the dependent operator’s default channel as the first 
choice, falling back to other channels the dependent operator provides as 
necessary.  Default channels for an operator package are determined by the 
order in which operator bundles are added to the catalog, with the last 
bundle’s default channel value being used.  Note the default channel is 
also used if you create a Subscription that doesn’t specify a channel.

If your operator bundles do not specify a default channel, a default channel 
will be picked by OLM based on the lexical ordering of the channels you have 
specified.  For example, if your bundles specified channels of candidate and 
stable, then candidate would be picked based solely on the names chosen and 
character ordering (e.g. ‘p’ comes before ‘s’).  Dependency resolution is 
described in more detail [here][dependency-resolution].

### Deploying Operators from Channels

When an end user or administrator wants to deploy an operator using OLM, 
they create a [Subscription][subscription] manifest, e.g:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: sample-subscription
  namespace: my-operators
spec:
  channel: candidate
  name: sampleoperator
  source: sample-operator
  sourceNamespace: my-operators
```

The [Subscription][subscription] is providing hints to OLM which are used to determine exactly which version of an operator will get deployed onto the cluster, in this example OLM will look for an operator to deploy that belongs to the candidate channel within a specified catalog source.  

Note that exactly which operator version is deployed can depend on more than what you specify in the [Subscription][subscription].  On initial install, OLM will always attempt to install whatever is the head of the specified channel by default.  Settings within the operator’s CSV also are used by OLM to determine exactly which operator version OLM will deploy or upgrade.

## NAMING

Channel names should imply the nature of official support the user can expect when subscribed to that channel for your operator. For example, the channel name `stable-v2` implies that subscribing to this channel will install an operator with a major version `v2` that you can expect official support for. The channel name `candidate-v2` implies that the user will be installing a candidate release version that does not have official supported.
		

Our motivation with this convention is to encourage a better user experience for OLM users to have an intuitive 
understanding of the level of maturity and supportability of the solutions that will get installed.
It can get very confusing for cluster admins and Operator consumers in general when each solution distributed in the OLM catalog adopts different names or different meanings for the same terminologies.

The names you choose are notional and up to you to decide, however, picking good channel names requires some basic guidance.  What is described below are different channel naming conventions that are commonly used by the operator community to denote different operator upgrade use cases.

### Naming Conventions

* Channel names are chosen by operator authors as they see fit to meet their upgrade strategies.
* Channel names should communicate the release strategy, official support level and the level of maturity, but **not** specific features. ( e.g. a channel with Operator versions which has official support ought to be have the word `stable` in the channel name, whereas a channel with Operator versions with a non-supported feature should have the phrase `tech-preview`in it's name. ).

> **Note:** If your new operator version release contains an API(CRD), which represents new experimental features and
> is not supported (like "tech-preview"), then the recommendation is to capture the maturity in the API version 
> (that is group: my.example.com, kind: Backup, version: v1alpha1) and not in the channel name. 
> This follows [Kubernetes API versioning](https://kubernetes.io/docs/reference/using-api/#api-versioning) recommendations.

* Channel names are unique to your operator and do not collide with channel names used by other operator providers.
* Seldom is there a situation where your channel names need to contain information about the Kubernetes or Openshift cluster version they run on.  Only in the case where your operator versions have a dependency on the Kubernetes/Openshift version would you include the cluster version in your channel name.
* You typically would **not** include product names in your channels since the channels are unique to your product and will not collide with other channel names used by other operators.
* You could include or have an operand version in your channel name to advertise to consumers the version of operand they can subscribe to.
* If you do choose to include some version in your channel name, it is important to include an additional identifier, to clarify what that the version number is referring to. A version number could equally be referring to product version (operand version), or operator version - these two don't always match: the operator itself can have different versioning than the product it is managing. 
* It is recommended to use at least the major versions of your Operator releases in the channel names. Cluster admins can then better plan the consumption of versions of Operators introducing breaking changes and avoid workflow issues. (e.g. `stable-v2.x`)

### Recommended Channel Naming

#### Example 1

| Channel Name       | Purpose | Supported |
| :------------- | :----------- | :----------- |
| candidate | Pre-release operators that would typically not have support offered and might be considered experimental. Release candidates contain all the features of the product but are not supported. Use release candidate versions to test feature acceptance and assist in qualifying the next version of Operator. A release candidate is any build that is available in the candidate channel, including ones that do not contain a pre-release version such as `-rc` in their names. After a version is available in the candidate channel, it goes through more quality checks. If it meets the quality standard, it is promoted to the `fast` or `stable` channels. Because of this strategy, if a specific release is available in both the `candidate` channel and in the `fast` or `stable` channels, it is a supported version. The `candidate` channel can include release versions from which there are no recommended updates in any channel. | No |
| fast | Released, supported operators which are still being monitored to assess stability/quality prior to promoting them as stable. Generally used by early adopters or for testing in pre-production environments. The `fast` channel ought to be updated with new and previous minor versions of the Operator as soon as it declares the given version as a general availability release. As such, these releases are fully supported, are production quality, and have performed well while available as a release candidate in the `candidate` channel from where they were promoted. Some time after a release appears in the `fast` channel, it is added to the `stable` channel. If you adopted the `fast` and/or `candidate` channel then, releases never should appear in the `stable` channel before they appears in the `fast` and/or `candidate`. Please, make sure you understand the [CHANNEL PROMOTION](/docs/best-practices/channel-naming/#channel-promotion).   | Yes |
| stable   | Released, supported operators that have been observed to be stable through usage by consumers of the fast channel. While the fast channel contains releases as soon as their are published with a support statement, releases are added to the stable channel after a delay in this case. During this delay, data could to be collected, for example, to ensure the stability of the release. | Yes |

With the above channel naming convention, you are always moving end users to the latest versions of your operator. For example, you could create a version `1.1.1` that is considered fast, adding it to the fast channel. Users can experiment with that fast version, but the stable version for example `1.2.0` would be added only to the stable channel.

**NOTE** The above terminology and support statements are very similar to the channels of distribution used by Kubernetes, (e.g [here](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels)), and popular vendors such as OpenShift (e.g [here](https://docs.openshift.com/container-platform/4.9/updating/understanding-upgrade-channels-release.html)). In this way, by adopting it you will bring a better and more intuitive understanding for the maintainers, users and community.

#### Example 2

By following the recommendation, you would provide the major versions of the Operators
in the channel naming. Consumers can then subscribe to a channel with confidence that none of the versions in the 
channel will introduce breaking changes:

| Channels for Operator version(s) v2.x | 
| :------------- | 
| candidate-v2 |
| fast-v2 | 
| stable-v2 |

**Attention:** The versions on the channel names are related to the Operator version and not its Operands.

#### Example 3 (Recommended Option is the most common scenarios)

An operator should be supported at various operator major/minor versions.  
For example, you might have a `v1.3` and also a `v2.4` releases of your operator that 
you need or want to offer support for at the same time.  However, you might 
not want to have OLM upgrade users to the `v2.4` Operator but instead keep them 
upgrading within the `v1.3` versions. In that case, you would end up with channels as 
recommended above but with major/minor version information applied as follows:

| Channels for v1.3 | Channels for v2.4 |
| :------------- | :----------- |
| candidate-v1.3 | candidate-v2.4 |
| fast-v1.3 | fast-v2.4 |
| stable-v1.3 | stable-v2.4 | 

**Attention:** The versions on the channel names are related to the Operator version and not its Operands.

#### Example 4 (Only if you need make clear for your users the Operand version)

Another form of channel naming might have the operand version be specified 
instead of the operator version.  For example, consider a database operator 
that has operands of different database versions such as Version 12 or 
Version 13.  In this case, you might have the need to advertise your 
channels by the operand version as follows:

| Channels for Postgres v12       | Channels for Postgres v13 |
| :------------- | :----------- |
| candidate-pg-v12 | candidate-pg-v13 |
| fast-pg-v12 | fast-pg-v13 |
| stable-pg-v12 | stable-pg-v13 | 

In this example, subscribers know which database version they are subscribing 
to and don’t necessarily care which operator version is being used, but will 
likely just want the latest operator version in that channel.  As with the 
previous naming convention examples, we start the channel name with 
candidate/fast/stable to denote the maturity level of the operator.  Using all 
3 naming prefixes is optional, you might only want to support a stable channel.

# CHANNEL PROMOTION

Channel promotion is the notion of moving an operator from one channel to 
another.  For example, consider the case where you have an operator version 
`1.0.1` which is found in a candidate channel, then you might decide to offer 
support for that version and want to move it to a stable channel.  

Today, channel promotion is achieved by creating a new operator version 
(`1.0.2`) that is labeled with the channel(s) you want to promote to (as well 
as any channels you want to keep it in).

# UPGRADES 

OLM provides a variety of ways to specify updates between operator versions. Before we continue with the following 
recommendations, make sure you understand the options by checking [Creating an update graph with OLM][upgrade-graph].

## Recommended upgrade path

Within a channel each patch release should be directly upgradable to the [HEAD of channel](/docs/glossary/#channel-head). 
Use skips or skipRange to provide this behaviour. (i.e. if you followed the above `Example 3` that means 
use skipRange to publish a patch for `3.6.z`under the`stable-v3.6` would mean setting the skipRange to be 
`>= 3.5.z < 3.6.z`, where `3.5.z` represents the oldest `3.5.z` version for which 
you can provide direct upgrade support to `3.6.z` latest)

#### Example

Let's imagine that you will be releasing the Operator bundle `v3.6.30` (patch release under the channel `stable-v3.6`) and
that you have published so far:

- Operator bundles versions from `v3.5.0` to `v3.5.25` under the `stable-v3.5` channel
- Operator bundles versions from `3.6.0` to `3.6.29` under the `stable-v3.6` channel

Then, in this case, your newer patch release `3.6.30` would be configured with `skipRange: >=3.5.25 < 3.6.30` in
order to only supports upgrading to the newest `3.6.z` from a pretty recent `3.5.z`. 

You do not need necessarily to use `3.5.25`. Therefore, you should 
use the oldest `3.5.z` version that supports upgrades from. Be aware that the ability to configure the path 
using this example from an Operator version like `3.5.25` _(or `3.5.17`, or something else)_ 
instead of `3.5.0` is a mechanism to constrain the support matrix when necessary, it's not the default recommendation.

**Note** If you would like to ensure that the users of your Operator are still able to install the Operator bundle version
`3.6.29` by using the option `startingCSV` added manually in the subscription then, you will need to also use the `replaces: 3.6.29`
to ensure the older Operator bundle does not get pruned from the index catalog via the OLM resolver.

#### Attention (Be aware of the following scenario)

If you have the channel `stable-v3.7` where the head of channel is `v3.7.10`, and you have a new patch release
with a bug fix using the Operator bundle version `v3.7.11` , and you configure `v3.7.11` to skip all
operator bundles published in the channel `stable-v3.7` (e.g.`v3.7.11` mentions  skipRange: `">= 3.7.0 < 3.7.11"` replaces: `3.6.z <latest release on 3.6 channel>` ).

, you could ensure that your users can more easily upgrade to the latest version since they will 
be able to install the new `3.7.11` release directly from `3.6.z <latest release on 3.6 channel>` instead of 
having to upgrade through Operator version `3.7.0` which may contain bugs that are already fixed in both the `3.6.z` 
version they had installed, and the `3.7.11` version they are moving to.

However, this approach has negative implications when you provide your next patch release to the minor channel `stable-v3.6`.  
Note that if you publish `3.6.latest+1` when this version comes out, and your users upgrade to it, they will have no way to
upgrade from `3.6.latest+1` to any solution published under the channel `stable-v3.7`, 
until you publish a new `3.7.z` version that replaces `3.6.latest+1.

[dependency-resolution]: https://olm.operatorframework.io/docs/concepts/olm-architecture/dependency-resolution/
[subscription]: https://olm.operatorframework.io/docs/concepts/crds/subscription/
[upgrade-graph]: https://olm.operatorframework.io/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/
