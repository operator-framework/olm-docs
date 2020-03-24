---
title: "Install your operator with OLM"
date: 2020-03-25
weight: 6
description: >
  [Once you've made your operator available in a catalog](/docs/tasks/make-operator-part-of-catalog/), or you've chosen an operator from the [list of operators available to be installed in the cluster](/docs/tasks/list-operators-available-to-install/), you can install your operator by creating a [`Subscription`](/docs/concepts/#subscriptions) to a specific [channel](/docs/concepts/#channel). 
---

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: <name-of-your-subscription>
  namespace: <namespace-you-want-your-operator-installed-in>
spec:
  channel: <channel-you-want-to-subscribe-to>
  name: <name-of-your-operator>
  source: <name-of-catalog-operator-is-part-of>
  sourceNamespace: <namespace-that-has-catalog>
 ``` 
For example, if you want to install an operator named `my-operator`, from a catalog named `my-catalog` that is in the namespace `olm`, and you want to subscribe to the channel `stable`, your subscription yaml would look like this: 

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: subs-to-my-operator
  namespace: olm
spec:
  channel: stable
  name: my-operator
  source: my-catalog
  sourceNamespace: olm
 ``` 

Once you have the subscription yaml, `kubectl apply -f Subscription.yaml` to install your operator. 

You can inspect your Subscription with `kubectl get subs <name-of-your-subscription> -n <namespace>`.

To ensure the operator installed successfully, check for the ClusterServiceVersion and the operator deployment in the namespace it was installed in. 

```
$ kubectl get csv -n <namespace-operator-was-installed-in>

NAME                  DISPLAY          VERSION           REPLACES              PHASE
<name-of-csv>     <operator-name>     <version>  <csv-of-previous-version>   Succeeded
```
```
$ kubectl get deployments -n <namespace-operator-was-installed-in>
NAME                         READY   UP-TO-DATE   AVAILABLE   AGE
<name-of-your-operator>      1/1     1            1           9m48s
```

If the ClusterServiceVersion fails to show up or does not reach the `Succeeded` phase, please check the [troubleshooting documentation](openshift/coming-soon.md)) to debug your installation. 