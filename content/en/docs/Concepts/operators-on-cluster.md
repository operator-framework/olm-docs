# When to use operators on a cluster

Operators are good for automating the knowledge of how to operate a complex system. Operators are a high-privilege component and by design, they run persistently inside your cluster. An operators can handle features like automatic scaling in response to load, backup and restore etc.

# How does OLM help and install operators on a cluster?

OLM requires you to provide metadata about your operator in order to ensure that it can be kept running safely on a cluster, and to provide information about how updates should be applied as you publish new versions of your operator. A ClusterServiceVersion (CSV) represents a particular version a running operator on a cluster. It includes metadata such as name, description, version, repository link, labels, icon, etc. It declares `owned`/`required` CRDs, cluster requirements, and install strategy that tells OLM how to create required resources and set up the operator.

As a cluster administrator, you can install an Operator from the OperatorHub using the OpenShift Container Platform web console or the CLI. You can then subscribe the Operator to one or more namespaces to make it available for developers on your cluster.

Example: Install the latest version of an Operator

Before installing an operator into a namespace, you will need to create an OperatorGroup that targets the namespaces your operator is planning to watch, to generate the required RBACs for your operator in those namespaces.

If you want to install an operator named `my-operator` in the namespace `foo` that is cluster scoped (i.e installModes:AllNamespaces), from a catalog named `my-catalog` that is in the namespace `olm`.

Create a global OperatorGroup (which selects all namespaces):
```
$ cat og.yaml

  apiVersion: operators.coreos.com/v1
  kind: OperatorGroup
  metadata:
    name: my-group
    namespace: foo

$ kubectl apply og.yaml
  operatorgroup.operators.coreos.com/my-group created
```
Then, create a subscription for the operator:
```
$ cat sub.yaml

apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: sub-to-my-operator
  namespace: foo
spec:
  channel: stable
  name: my-operator
  source: my-catalog
  sourceNamespace: olm
  installPlanApproval: Manual

$ kubectl apply -f sub.yaml
subscription.operators.coreos.com/sub-to-my-operator created
```

Since the approval is Manual, we need to manually go in and approve the InstallPlan

```
$ kubectl get ip -n foo

NAME            CSV                   APPROVAL    APPROVED
install-nlwcw   my-operator.v0.9.2   Automatic     false

$ kubectl edit ip install-nlwcw -n foo
```
And then change the `spec.approved` from `false` to `true`

This should spin up the `ClusterServiceVersion` of the operator in the `foo` namespace`, following which the operator pod will spin up.

To ensure the operator installed successfully, check for the `ClusterServiceVersion` and the operator deployment in the namespace it was installed in.
```
$ kubectl get csv -n <namespace-operator-was-installed-in>

NAME                  DISPLAY          VERSION           REPLACES              PHASE
<name-of-csv>     <operator-name>     <version>  <csv-of-previous-version>   Succeeded
...
$ kubectl get deployments -n <namespace-operator-was-installed-in>
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
<name-of-your-operator>      1/1     1            1           9m48s
```
