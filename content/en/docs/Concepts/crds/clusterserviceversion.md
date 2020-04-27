---
title: "ClusterServiceVersion"
weight: 2
---

A ClusterServiceVersion(CSV) represents a particular version of a ClusterService and its operator. It includes metadata such as name, description, version, repository link, labels, icon, etc. It declares `owned`/`required` CRDs, cluster requirements, and install strategy that tells OLM how to create required resources and set up the operator as a [deployment](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/).

{{% alert title="Warning" color="warning" %}} 
This section is under construction.
{{% /alert %}}

