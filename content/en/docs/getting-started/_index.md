---
title: "QuickStart"
linkTitle: "QuickStart"
weight: 1
description: >
  Install OLM in a kubernetes cluster, then install an operator using OLM.
---

## Prerequisites

- Access to a Kubernetes `v1.11.3+` cluster.
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) `v1.11.3+`.

## Installing OLM in your cluster

The `operator-sdk` binary provides a command to easily install and uninstall OLM in a Kubernetes cluster. See the [SDK installation guide][sdk-installation-guide] on how to install `operator-sdk` tooling.

Once you have the `operator-sdk` binary installed, you can easily install OLM on your cluster by running `operator-sdk olm install`. 

```bash 
$ operator-sdk olm install 
INFO[0000] Fetching CRDs for version "latest"           
INFO[0000] Fetching resources for resolved version "latest" 
I0428 10:07:00.985939 3850425 request.go:655] Throttling request took 1.046148019s, request: GET:https://127.0.0.1:45457/apis/storage.k8s.io/v1beta1?timeout=32s
INFO[0008] Creating CRDs and resources                  
INFO[0008]   Creating CustomResourceDefinition "catalogsources.operators.coreos.com" 
INFO[0008]   Creating CustomResourceDefinition "clusterserviceversions.operators.coreos.com" 
INFO[0008]   Creating CustomResourceDefinition "installplans.operators.coreos.com" 
INFO[0008]   Creating CustomResourceDefinition "operatorconditions.operators.coreos.com" 
INFO[0008]   Creating CustomResourceDefinition "operatorgroups.operators.coreos.com" 
INFO[0008]   Creating CustomResourceDefinition "operators.operators.coreos.com" 
INFO[0008]   Creating CustomResourceDefinition "subscriptions.operators.coreos.com" 
INFO[0008]   Creating Namespace "olm"                   
INFO[0008]   Creating Namespace "operators"             
INFO[0008]   Creating ServiceAccount "olm/olm-operator-serviceaccount" 
INFO[0008]   Creating ClusterRole "system:controller:operator-lifecycle-manager" 
INFO[0008]   Creating ClusterRoleBinding "olm-operator-binding-olm" 
INFO[0008]   Creating Deployment "olm/olm-operator"     
INFO[0008]   Creating Deployment "olm/catalog-operator" 
INFO[0008]   Creating ClusterRole "aggregate-olm-edit"  
INFO[0008]   Creating ClusterRole "aggregate-olm-view"  
INFO[0008]   Creating OperatorGroup "operators/global-operators" 
INFO[0010]   Creating OperatorGroup "olm/olm-operators" 
INFO[0010]   Creating ClusterServiceVersion "olm/packageserver" 
INFO[0012]   Creating CatalogSource "olm/operatorhubio-catalog" 
INFO[0012] Waiting for deployment/olm-operator rollout to complete 
INFO[0012]   Waiting for Deployment "olm/olm-operator" to rollout: 0 of 1 updated replicas are available 
INFO[0026]   Deployment "olm/olm-operator" successfully rolled out 
INFO[0026] Waiting for deployment/catalog-operator rollout to complete 
INFO[0026]   Waiting for Deployment "olm/catalog-operator" to rollout: 0 of 1 updated replicas are available 
INFO[0031]   Deployment "olm/catalog-operator" successfully rolled out 
INFO[0031] Waiting for deployment/packageserver rollout to complete 
INFO[0031]   Waiting for Deployment "olm/packageserver" to rollout: 0 of 2 updated replicas are available 
INFO[0037]   Deployment "olm/packageserver" successfully rolled out 
INFO[0037] Successfully installed OLM version "latest"  

NAME                                            NAMESPACE    KIND                        STATUS
catalogsources.operators.coreos.com                          CustomResourceDefinition    Installed
clusterserviceversions.operators.coreos.com                  CustomResourceDefinition    Installed
installplans.operators.coreos.com                            CustomResourceDefinition    Installed
operatorconditions.operators.coreos.com                      CustomResourceDefinition    Installed
operatorgroups.operators.coreos.com                          CustomResourceDefinition    Installed
operators.operators.coreos.com                               CustomResourceDefinition    Installed
subscriptions.operators.coreos.com                           CustomResourceDefinition    Installed
olm                                                          Namespace                   Installed
operators                                                    Namespace                   Installed
olm-operator-serviceaccount                     olm          ServiceAccount              Installed
system:controller:operator-lifecycle-manager                 ClusterRole                 Installed
olm-operator-binding-olm                                     ClusterRoleBinding          Installed
olm-operator                                    olm          Deployment                  Installed
catalog-operator                                olm          Deployment                  Installed
aggregate-olm-edit                                           ClusterRole                 Installed
aggregate-olm-view                                           ClusterRole                 Installed
global-operators                                operators    OperatorGroup               Installed
olm-operators                                   olm          OperatorGroup               Installed
packageserver                                   olm          ClusterServiceVersion       Installed
operatorhubio-catalog                           olm          CatalogSource               Installed

```

## Installing an Operator using OLM

When you install OLM, it comes packaged with a number of Operators developed by the community that you can install instantly.
You can use the `packagemanifest` api to see the operators available for you to install in your cluster:

```sh
$ kubectl get packagemanifest -n olm
NAME                               CATALOG               AGE
cassandra-operator                 Community Operators   26m
etcd                               Community Operators   26m
postgres-operator                  Community Operators   26m
prometheus                         Community Operators   26m
wildfly                            Community Operators   26m
```

To install the etcd operator in the default namespace, first create an `OperatorGroup` for the default namespace:

```sh
$ cat operatorgroup.yaml
kind: OperatorGroup
apiVersion: operators.coreos.com/v1
metadata:
  name: og-single
  namespace: default
spec:
  targetNamespaces:
  - default

$ kubectl apply -f operatorgroup.yaml
operatorgroup.operators.coreos.com/og-single created
```

Then create a subscription for the etcd operator:

```sh
$ cat subscription.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: etcd
  namespace: default
spec:
  channel: singlenamespace-alpha
  installPlanApproval: Automatic
  name: etcd
  source: operatorhubio-catalog
  sourceNamespace: olm
  startingCSV: etcdoperator.v0.9.2

$ kubectl apply -f subscription.yaml
subscription.operators.coreos.com/etcd created
```

This installs the v0.9.2 version of the etcd operator, and then upgrades to the latest version of the etcd operator in your cluster.

```sh
$ kubectl get sub -n default
NAME   PACKAGE   SOURCE                  CHANNEL
etcd   etcd      operatorhubio-catalog   singlenamespace-alpha

$ kubectl get csv -n default
NAME                  DISPLAY   VERSION   REPLACES              PHASE
etcdoperator.v0.9.4   etcd      0.9.4     etcdoperator.v0.9.2   Succeeded

$ kubectl get deployment -n default
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
etcd-operator   1/1     1            1           3m29s
```

To learn more about packaging your operator for OLM, installing/uninstalling an operator etc, visit the [Core Tasks](/docs/tasks/) and the [Advanced Tasks](/docs/advanced-tasks/) sections of this site.


[sdk-installation-guide]: https://sdk.operatorframework.io/docs/installation/
