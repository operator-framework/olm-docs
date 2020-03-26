---
title: "Cluster Service Version"
linkTitle: "Cluster Service Version"
weight: 4
description: >
  This guide introduces the concept of Cluster Service Version(CSV) in OpenShift Lifecycle Manager.
---


{{% alert title="Warning" color="warning" %}}
These pages are under construction. 
**ToDo: Complete this**
{{% /alert %}}


###  Definition
The ClusterServiceVersion represents a particular version of a ClusterService and its operator. It includes metadata such as name, description, version, repository link, labels, icon, etc. It declares `owned`/`required` CRDs, cluster requirements, and install strategy that tells OLM how to create required resources and set up the operator as a [deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).
