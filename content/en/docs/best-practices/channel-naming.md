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
  
  - A catalog index named “vendor:v4.6”, this catalog is built by a cluster administrator typically
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
described in more detail here.

### Deploying Operators from Channels

When an end user or administrator wants to deploy an operator using OLM, 
they create a Subscription.  For example, here is a Subscription manifest:

```
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

The Subscription is providing hints to OLM which are used to determine exactly which version of an operator will get deployed onto the cluster, in this example OLM will look for an operator to deploy that belongs to the candidate channel within a specified catalog index source.  

Note that exactly which operator version is deployed can depend on more than what you specify in the Subscription.  On initial install, OLM will always attempt to install whatever is the head of the specified channel by default.  Settings within the operator’s CSV also are used by OLM to determine exactly which operator version OLM will deploy or upgrade.

## NAMING

Channel names are used to imply what form of upgrade you want to offer for your operator.  For example, you might have an operator that has a candidate or alpha version which is not supported as well as a version where support is offered.

The names you choose are notional and up to you to decide, however, picking good channel names requires some basic guidance.  What is described below are different channel naming conventions that are commonly used by the operator community to denote different operator upgrade use cases.

### Naming Conventions

* Channel names are chosen by operator authors as they see fit to meet their upgrade strategies.
* Channel names are unique to your operator and do not collide with channel names used by other operator providers.
* Seldom is there a situation where your channel names need to contain information about the Kubernetes or Openshift cluster version they run on.  Only in the case where your operator versions have a dependency on the Kubernetes/Openshift version would you include the cluster version in your channel name.
* You typically would not include product names in your channels since the channels are unique to your product and will not collide with other channel names used by other operators.
* You could include or have an operand version in your channel name to advertise to consumers the version of operand they can subscribe to.
* If you do choose to include some version in your channel name, it is important to include an additional identifier, to clarify what that the version number is referring to. A version number could equally be referring to product version (operand version), or operator version - these two don't always match: the operator itself can have different versioning than the product it is managing. 


### Recommended Channel Naming

#### Example 1

| Channel Name       | Purpose | Supported |
| :------------- | :----------- | :----------- |
| candidate | Pre-release operators that would typically not have support offered and might be considered experimental. Release candidates contain all the features of the product but are not supported. Use release candidate versions to test feature acceptance and assist in qualifying the next version of Operator. A release candidate is any build that is available in the candidate channel, including ones that do not contain a pre-release version such as `-rc` in their names. After a version is available in the candidate channel, it goes through more quality checks. If it meets the quality standard, it is promoted to the `fast` or `stable` channels. Because of this strategy, if a specific release is available in both the `candidate` channel and in the `fast` or `stable` channels, it is a supported version. The `candidate` channel can include release versions from which there are no recommended updates in any channel. | No |
| fast | Released, supported operators which are still being monitored to assess stability/quality prior to promoting them as stable. Generally used by early adopters or for testing in pre-production environments. The `fast` channel ought to be updated with new and previous minor versions of the Operator as soon as it declares the given version as a general availability release. As such, these releases are fully supported, are production quality, and have performed well while available as a release candidate in the `candidate` channel from where they were promoted. Some time after a release appears in the `fast` channel, it is added to the `stable` channel. If you adopted the `fast` and/or `candidate` channel then, releases never should appear in the `stable` channel before they appears in the `fast` and/or `candidate`. Please, make sure you understand the [CHANNEL PROMOTION](/docs/best-practices/channel-naming/#channel-promotion).   | Yes |
| stable   | Released, supported operators that have been observed to be stable through usage by consumers of the fast channel. While the fast channel contains releases as soon as their are published with a support statement, releases are added to the stable channel after a delay in this case. During this delay, data could to be collected, for example, to ensure the stability of the release. | Yes |

With the above channel naming convention, you are always moving end users to 
the latest versions of your operator.  For example, you could create a 
version `1.1.1` that is considered fast, adding it to th fast channel.  Users 
can experiment with that fast version, but the stable version for example 
`1.2.0` would be added only to the stable channel.

**NOTE** The above terminology and support statements are very similar to the channels of distribution used by Kubernetes, (e.g [here](https://cloud.google.com/kubernetes-engine/docs/concepts/release-channels)), and popular vendors such as OpenShift (e.g [here](https://docs.openshift.com/container-platform/4.7/updating/updating-cluster-between-minor.html)). In this way, by adopting it you will bring a better and more intuitive understanding for the maintainers, users and community.

#### Example 2

A possible but less typical case might be where an operator wants to be 
supported at various operator major/minor versions  For example you might 
have an operator version at 1.3 and also at 2.4 that you need or want to 
offer support for at the same time.  However, you might not want to have 
OLM upgrade users to the 2.4 operator but instead keep them upgrading within 
the 1.3 versions.   In that case, you would end up with channels as 
recommended above but with major/minor version information applied as follows:

| Channels for 1.3 | Channels for 2.4 |
| :------------- | :----------- |
| candidate-1.3 | candidate-2.4 |
| fast-1.3 | fast-2.4 |
| stable-1.3 | stable-2.4 \| |

#### Example 3

Another form of channel naming might have the operand version be specified 
instead of the operator version.  For example, consider a database operator 
that has operands of different database versions such as Version 12 or 
Version 13.  In this case, you might have the need to advertise your 
channels by the operand version as follows:

| Channels for Postgres 12       | Channels for Postgres 13 |
| :------------- | :----------- |
| candidate-pg-12 | candidate-pg-13 |
| fast-pg-12 | fast-pg-13 |
| stable-pg-12 | stable-pg-13 | |

In this example, subscribers know which database version they are subscribing 
to and don’t necessarily care which operator version is being used, but will 
likely just want the latest operator version in that channel.  As with the 
previous naming convention examples, we start the channel name with 
candidate/fast/stable to denote the maturity level of the operator.  Using all 
3 naming prefixes is optional, you might only want to support a stable channel.

# CHANNEL PROMOTION

Channel promotion is the notion of moving an operator from one channel to 
another.  For example, consider the case where you have an operator version 
1.0.1 which is found in a candidate channel, then you might decide to offer 
support for that version and want to move it to a stable channel.  

Today, channel promotion is achieved by creating a new operator version 
(1.0.2) that is labeled with the channel(s) you want to promote to (as well 
as any channels you want to keep it in).
