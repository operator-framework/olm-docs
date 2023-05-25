---
title: "Catalog Update Formulary"
linkTitle: "Catalog Formulary"
weight: 5
---

## Background
[File-based-catalogs][file-based-catalog-spec] (FBC) and [catalog templates][templates-doc] (templates)  empower operator authors with public, standardized schemas to express operator upgrade graphs.  These schemas eliminate the reliance for operator-framework tooling to support common processing paths.  One disadvantage to authors may be that in the absence of explicit tooling, it isn't always clear how to achieve routine goals, especially as the number of available bundle versions increases and increases the complexity of the upgrade graph.  This document is an attempt to establish a formulary of common operations, specificially with the intention of making these pieces automatable.  This is in no way an exhaustive list.

## Conventions
Formulae will be identified as pertaining to either FBC or [semver catalog template][semver-template-doc] (semver template).  Since FBC and the [basic catalog template][basic-template-doc] (basic template) both represent the upgrade graph in the set of `olm.channel` objects, instructions for FBC will also be applicable to the `basic template`. Manipulations of `olm.bundle` attributes are limited to FBC representation only. 
Schema manipulations will be modeled using YAML and [yq][yq].  Wherever possible, example input will be limited to the relevant object hierarchies.  Truncation is indicated by elipses (...) before and after the text.


## Examples
For brevity, all formulae will refer to the same example, for semver template and FBC.  For convenience, all semver bundle image pullspecs will express versions which match the bundle version (instead of SHAs). 

### semver template example
Formulae presume the following content is saved to the file `semver.yaml`
```yaml
schema: olm.semver
generatemajorchannels: false
generateminorchannels: true
candidate:
  bundles:
  - image: quay.io/organization/testoperator:v1.0.0
  - image: quay.io/organization/testoperator:v1.0.1
  - image: quay.io/organization/testoperator:v1.1.0
fast:
  bundles:
  - image: quay.io/organization/testoperator:v1.0.1
  - image: quay.io/organization/testoperator:v1.1.0
stable:
  bundles:
  - image: quay.io/organization/testoperator:v1.0.1
  ```


### FBC example
Formulae presume the following content is saved to the file `fbc.yaml`

```yaml
---
defaultChannel: stable-v1.0
name: testoperator
schema: olm.package
---
entries:
  - name: testoperator.v1.0.0
  - name: testoperator.v1.0.1
    skips:
      - testoperator.v1.0.0
name: candidate-v1.0
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v1.1.0
    replaces: testoperator.v1.0.1
    skips:
      - testoperator.v1.0.0
name: candidate-v1.1
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v1.0.1
name: fast-v1.0
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v1.1.0
    replaces: testoperator.v1.0.1
name: fast-v1.1
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v1.0.1
name: stable-v1.0
package: testoperator
schema: olm.channel
```

### rendered `olm.bundle` FBC example
Formulae presume the following content is saved to the file `bundle.yaml`

```yaml
---
image: quay.io/organization/testoperator:v1.1.0
name: testoperator.v1.1.0
package: testoperator
properties:
- type: olm.package
  value:
    packageName: testoperator
    version: 1.1.0
- type: olm.gvk
  value:
    group: api.testoperator.io
    kind: Instance
    version: v1alpha1
relatedImages:
- image: busybox
  name: ""
- image: quay.io/organization/testoperator:v1.1.0
  name: ""
schema: olm.bundle
```

## Formulae

### Adding a new bundle to an existing channel
#### semver
Add a new `testoperatorv1.1.1` bundle pullspec to the `Candidate` channel archetype

```bash
yq eval '.candidate.bundles += [{"image" : "quay.io/organization/testoperator:v1.1.1"}]' semver.yaml
```

produces updated `Candidate` archetype contents:

```yaml
...
candidate:
  bundles:
  - image: quay.io/organization/testoperator:v1.0.0
  - image: quay.io/organization/testoperator:v1.0.1
  - image: quay.io/organization/testoperator:v1.1.0
  - image: quay.io/organization/testoperator:v1.1.1
...
```

#### FBC
Add a new `testoperator.v1.1.1` edge to an existing `candidate-v1.1` channel

```bash
yq eval 'select(.schema=="olm.channel" and .name == "candidate-v1.1").entries += [{"name" : "testoperator.v1.1.1"}]' fbc.yaml
```

produces updated `candidate-v1.1` channel:

```yaml
...
entries:
  - name: testoperator.v1.1.0
    replaces: testoperator.v1.0.1
    skips:
      - testoperator.v1.0.0
  - name: testoperator.v1.1.1
name: candidate-v1.1
package: testoperator
schema: olm.channel
...
```


### Adding a new 'replaces' link between two existing bundles

#### FBC
Adding a new `testoperator.v1.1.1` bundle version edge with a replaces link to its predecessor `testoperator.v1.1.0` version which already exists in the channel. 

```bash
yq eval 'select(.schema == "olm.channel" and .name == "candidate-v1.1").entries += [{"name" : "testoperator:v1.1.1", "replaces": "testoperator:v1.1.0"}]' fbc.yaml
```
produces updated `candidate-v1.1` channel:

```yaml
...
entries:
  - name: testoperator.v1.1.0
    replaces: testoperator.v1.0.1
    skips:
      - testoperator.v1.0.0
  - name: testoperator:v1.1.1
    replaces: testoperator:v1.1.0
name: candidate-v1.1
package: testoperator
schema: olm.channel
...
```

### Removing a specific bundle version

#### FBC
Remove the upgrade edge from the example `candidate-v1.1` channel which refers to bundle version `testoperator.v1.1.0`. 

```bash
yq eval 'del(select(.schema == "olm.channel" and .name == "candidate-v1.1" ).entries[]| select(.name == "testoperator.v1.1.0"))' fbc.yaml
```

produces updated `candidate-v1.1` channel:

```yaml
...
entries: []
name: candidate-v1.1
package: testoperator
schema: olm.channel
...
```
Please note that removing the only edge for a channel as in this example will yield an explicitly empty array.  This will produce an error in `opm validate`. 

### Substituting a bundle version in the upgrade graph

#### semver
For all channels, replace instances of `quay.io/organization/testoperator:v1.1.0` with `quay.io/organization/testoperator:v1.1.0-CVE`

```bash
yq '(..| select(has("image") and .image == "quay.io/organization/testoperator:v1.1.0")).image = "quay.io/organization/testoperator:v1.1.0-cve"' semver.yaml
```
produces updated template:

```yaml
schema: olm.semver
generatemajorchannels: false
generateminorchannels: true
candidate:
  bundles:
    - image: quay.io/organization/testoperator:v1.0.0
    - image: quay.io/organization/testoperator:v1.0.1
    - image: quay.io/organization/testoperator:v1.1.0-cve
fast:
  bundles:
    - image: quay.io/organization/testoperator:v1.0.1
    - image: quay.io/organization/testoperator:v1.1.0-cve
stable:
  bundles:
    - image: quay.io/organization/testoperator:v1.0.1
```

#### FBC
For all graph edges, replaces instances of `testoperator.v1.1.0` with a different bundle version `testoperator.v1.1.0-CVE`

```bash
yq '(.. | select(has("entries") and .entries[].name == "testoperator.v1.1.0" ).entries[]).name = "testoperator.v1.1.0-cve"' fbc.yaml
```

produces updated channels:

```yaml
---
defaultChannel: stable-v1.0
name: testoperator
schema: olm.package
---
entries:
  - name: testoperator.v1.0.0
  - name: testoperator.v1.0.1
    skips:
      - testoperator.v1.0.0
name: candidate-v1.0
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v1.1.0-cve
    replaces: testoperator.v1.0.1
    skips:
      - testoperator.v1.0.0
name: candidate-v1.1
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v1.0.1
name: fast-v1.0
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v1.1.0-cve
    replaces: testoperator.v1.0.1
name: fast-v1.1
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v1.0.1
name: stable-v1.0
package: testoperator
schema: olm.channel
```

### Introducing a new replacement relationship in the upgrade graph
#### FBC
Substitute an existing 'replaces' link target for `testoperator.v1.1.0` with a different bundle version `testoperator.v1.0.1`.


```bash
yq eval 'select(.schema == "olm.channel" and .name == "candidate-v1.1").entries |= [{"name" : "testoperator:v1.1.0", "replaces": "testoperator:v1.0.0"}]' fbc.yaml
```
 produces updated `candidate-v1.1` channel:

```yaml
...
entries:
  - name: testoperator:v1.1.0
    replaces: testoperator:v1.0.0
name: candidate-v1.1
package: testoperator
schema: olm.channel
...
```

### Adding a new property to an `olm.bundle`

#### FBC
Creating a new property associated with a FBC bundle.  This example marks a bundle as deprecated to prevent installation. 

```bash
yq eval 'select(.name == "testoperator.v1.1.0" and .schema == "olm.bundle").properties += [{"type" : "olm.deprecated", "value" : "true"}]' bundle.yaml
```

produces updated `testoperator.v1.1.0` `olm.bundle`:

```yaml
...
---
image: quay.io/organization/testoperator:v1.1.0
name: testoperator.v1.1.0
package: testoperator
properties:
  - type: olm.package
    value:
      packageName: testoperator
      version: 1.1.0
  - type: olm.deprecated
    value: "true"
relatedImages:
  - image: busybox
    name: ""
  - image: quay.io/organization/testoperator:v1.1.0
    name: ""
schema: olm.bundle
...
```

### Modifying an existing property of an `olm.bundle`

#### FBC
Update an existing property associated with a FBC bundle.  This example promotes the GVK version of `testoperator.v1.1.0` from `v1alpha1` to `v1`. 

```bash
yq eval 'select(.name == "testoperator.v1.1.0" and .schema == "olm.bundle").properties |= [{"type" : "olm.gvk", "value" : {"group": "api.testoperator.io", "kind" : "Instance", "version": "v1"}}]' bundle.yaml
```

produces updated `testoperator.v1.1.0` `olm.bundle`:

```yaml
...
image: quay.io/organization/testoperator:v1.1.0
name: testoperator.v1.1.0
package: testoperator
properties:
  - type: olm.gvk
    value:
      group: api.testoperator.io
      kind: Instance
      version: v1
relatedImages:
  - image: busybox
    name: ""
  - image: quay.io/organization/testoperator:v1.1.0
    name: ""
schema: olm.bundle
...
```








[file-based-catalog-spec]: /docs/reference/file-based-catalogs
[templates-doc]: /docs/reference/catalog-templates
[basic-template-doc]: /docs/reference/catalog-templates#basic-template
[semver-template-doc]: /docs/reference/catalog-templates#semver-template
[yq]: https://github.com/mikefarah/yq