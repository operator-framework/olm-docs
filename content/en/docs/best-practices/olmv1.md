---
title: "Cluster-level operators"
linkTitle: "Cluster-level operators"
weight: 2
description: Transition from Namespace-scoped operators to Cluster-level operators, highlighting the rationale and best practices associated with cluster-level operators.
---

# Transitioning to OLM v1

A significant change for OLM(Operator Lifecycle Manager) v1 is its alignment with the inherent cluster-scoped nature of Custom Resource Definitions(CRDs). While specifics are in development, this section offers insights into the underlying reasoning, prospective direction, and recommended practices.

### 1. A Comparative Glimpse: OLM v0.x vs. OLM v1.x
 The diagram below provides a side-by-side comparison, capturing the evolution from OLM v0.x to OLM v1.x.

<div style="text-align: center;">
    <img src="images/olmv0-v1.png" height="200">
</div>

### 2. Understanding the Need for Change
CRDs are fundamentally designed with a cluster-level scope. Having a namespace-scoped operator counteracts this fundamental design, potentially leading to complexities and inconsistencies. The shift towards a cluster-scoped operator model in OLM v1 is, therefore, a step towards better aligning with the essence of CRDs.

To offer a clearer picture of what might be problematic with namespace-scoped operator, take a look at the following comparison between the existing namespaced-scope operator and the proposed cluster-level operator.

<div style="text-align: center;">
    <img src="images/namespace-cluster.png" height="200">
</div>

A challenge with operators scoped to namespaces arises when the operator is deployed across multiple namespaces, leading to conflicts with OLM v0.

On the left of the diagram for example, consider PostgressOperator v1.2 being deployed in tenant namespace A, while PostgresOperator v2.4, with updated schema changes, is situated in tenant namespace B. When PostgresOperator v1.2 is subsequently installed in a different namespace, it compromises the functionality of PostgresOperator v2.4. This occurs because the installation of v1.2 overwrites the schema for v2.4, given that they both share a single CRD. As a result, the two versions clash due to their reliance on the identical CRD.

In OLM v1, the operator functions at the cluster level. However, it doesn't grant visibility to all tenants by default.

On the right side of the diagram showcases PostgresOperator v1.2 as the cluster-level operator. The visibility is adjustable, enabling access for designated tenants only. The Operator object, a part of OLM v1, is responsible for deciding which tenants have viewing permissions. Administrators can modify these settings, ensuring the operator is accessible only to a selected subset of tenants within the cluster.

### 3. The Prospective OLM Model
OLM v1 aims for a more streamlined, cluster-wide singleton model, ideally suited for operators built for the “AllNamespace” installation mode.

### 4. Ongoing Relevance of OLM v0.x
Even as changes are anticipated, OLM v0.x retains its importance. It is understood that OLM v0.x will continue throughout the life of OpenShift 4, potentially shifting to maintenance mode when OLM v1.0 emerges.


### 5. Best Practices for Cluster-Scoped Operators
<div style="text-align: center;">
    <img src="images/bestpractice.png" height="200">
</div>

### The Operator needs to support Multi-tenancy
  

#### 1. Drop Assumptions of Multiple Operator Instances:
    
   - Let's say you have an operator that deploys an application, AppX, and you have instances of this operator in multiple namespaces each deploying its own instance of AppX. This approach needs to be altered. In the cluster-scoped model, you'll have **a single instance of your operator** that manages all instances of AppX across all namespaces.

   - When moving from namespace-scoped to cluster-scoped, you must modify the manager setup in `main.go` by removing ```Namespace: namespace```. 
   - By default, it manages resources cluster wide.

   ```go
mgr, err := ctrl.NewManager(ctrl.GetConfigOrDie(), ctrl.Options{
    Scheme:             scheme,
    Namespace:          namespace,  // Remove this line
    MetricsBindAddress: metricsAddr,
    ...
})
   ```


#### 2. Reconcile every object within its namespace:
   - Reconcile object in the namespace where the request is been made.
   
       - In `controllers/memcached_controller.go`, you might have something like:
```go
    podList := &corev1.PodList{}
    listOpts := []client.ListOption{
        client.InNamespace(memcached.Namespace),
        client.MatchingLabels(labelsForMemcached(memcached.Name)),
    }
    if err = r.List(ctx, podList, listOpts...); err != nil {
        log.Error(err, "Failed to list pods", "Memcached.Namespace", memcached.Namespace, "Memcached.Name", memcached.Name)
        return ctrl.Result{}, err
    }
   ```


#### 3. Read/store configuration or credentials only in the namespace in which the request came from:
   - The operator should expect credentials coming from one or more tenants essentially support multi-tenancy.
   - If your operator uses a `Secret` to store credentials, ensure that it reads the `Secret` from the namespace of the `Memcached` custom resource rather than the operator's namespace.


```go
func (r *DatabaseReconciler) Reconcile(ctx context.Context, req ctrl.Request) (ctrl.Result, error) {
    // Assume secret is in database's namespace
    secret := &corev1.Secret{}
    if err := r.Get(ctx, client.ObjectKey{Name: "my-secret", Namespace: req.Namespace}, secret); err != nil {
        return ctrl.Result{}, err
    }
    // Use secret...
}
```

#### 4. Provide the ability to serve different versions of your managed application / driver:
   - Instead of harcode the managed application version, include a `version` field in the CRD that specifies which version to deploy.
   - Let the tenant decides which version of the application to deploy 

#### 5. Evolve your operator APIs with non-breaking changes by adding CRD versions:
   - If you need to change the schema of your CRD (for example, adding a new optional field), you should create a new version of your CRD (e.g., v1beta2), keeping the old one (e.g., v1beta1) for backward compatibility.

#### 6. Keep support older CRD versions for as long as possible:
   - Continuing with the previous example, your operator should be capable of managing resources created with both v1beta1 and v1beta2 CRDs.

#### 7. Do not remove CRD versions unless you release a new major version of your operator:
   - Suppose you decide to remove the v1beta1 version of the CRD. You should plan to do this only when you're ready to release a new major version of your operator, so users are aware that this is a breaking change.

#### 8. If breaking changes to APIs are required, use CRD conversion webhooks if any possible:
   - If you need to introduce a breaking change to your CRD, use a conversion webhook. This webhook could, for example, automatically convert a v1beta1 object to a v1beta2 object when the user tries to interact with it, preserving backward compatibility.

#### 9. Do not assume or require cluster-scoped permissions or permissions on cluster-scoped APIs:
   - Your operator should still work with the least amount of privileges necessary. If it used to need permissions to read a certain ConfigMap in its own namespace, now it needs permissions to read that ConfigMap in any namespace. But it doesn't suddenly need permissions to read all ConfigMaps in all namespaces.

### 6. Upcoming Milestones
#### Version 4.14: 
The operator resource is available via CLI

#### Version 4.15: 
Further details are being formulated, with GA but limited support
   - clusterscope operator will be picked up by the new OLM API.
   - WATCHNAMESPACE env variable, part of the operatorgroup, does not exist in v1.
