---
title: "Catalog Update Formulary"
linkTitle: "Catalog Formulary"
weight: 5
---

## Background
[File-based-catalogs][file-based-catalog-spec] (FBC) and [catalog templates][templates-doc] (templates)  provide operator authors with standardized schemas to express operator upgrade graphs.  However, without explicit tooling users require clear examples of how to achieve routine goals.  This document is an attempt to establish a formulary of common operations, specifically with the intention of making these pieces automatable.  This is in no way an exhaustive list.

## Conventions
Formulae will be identified as FBC, [basic catalog template][basic-template-doc] (basic template), or [semver catalog template][semver-template-doc] (semver template).
Schema manipulations will be modeled using YAML and [yq][yq].  Wherever possible, example input will be limited to the relevant object hierarchies.  Truncation is indicated by elipses (...) before and after the text.

## Examples
For brevity, all formulae will refer to the same example, for semver template and FBC.  For convenience, all semver bundle image pullspecs will express versions which match the bundle version (instead of SHAs). 

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


### basic template example
Formulae presume the following context is saved to the file `basic.yaml`
```yaml
schema: olm.template.basic
entries:
  - schema: olm.package
    name: testoperator
    defaultChannel: stable
  - schema: olm.channel
    package: testoperator
    name: stable
    entries:
      - name: testoperator.v0.1.0
      - name: testoperator.v0.2.0
        replaces: testoperator.v0.1.0
  - schema: olm.bundle
    image: quay.io/organization/testoperator:v0.1.0
  - schema: olm.bundle
    image: quay.io/organization/testoperator:v0.2.0
```

### semver template example
Formulae presume the following content is saved to the file `semver.yaml`
```yaml
schema: olm.semver
generateMajorChannels: false
generateMinorChannels: true
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





## Formulae

### Adding a new bundle to an existing channel

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
{{% alert title="Warning" color="warning" %}}
This example illustrates how it is possible to inadvertently create multiple channel heads
`opm validate` result for this output would be:

```bash
FATA[0000] invalid index:
└── invalid package "testoperator":
    └── invalid channel "candidate-v1.1":
        ├── multiple channel heads found in graph: testoperator.v1.1.0, testoperator.v1.1.1
```
{{% /alert %}}

#### basic
Add a new `testoperator.v0.2.1` bundle pullspec to the existing `stable` channel

```bash
yq eval 'select(.schema == "olm.template.basic").entries[] |= select(.schema == "olm.channel" and .name == "stable").entries += [{"name" : "testoperator.v0.2.1", "replaces": "testoperator.v0.2.0"}]' basic.yaml
```

produces updated `stable` channel:

```yaml
...
  - schema: olm.channel
    package: testoperator
    name: stable
    entries:
      - name: testoperator.v0.1.0
      - name: testoperator.v0.2.0
        replaces: testoperator.v0.1.0
      - name: testoperator.v0.2.1
        replaces: testoperator.v0.2.0
...
```

#### semver
Add a new `testoperator.v1.1.1` bundle pullspec to the `Candidate` channel archetype

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


### Adding a new 'replaces' link between two existing bundles
{{% alert title="Note" color="info" %}}
This operation is not possible for the semver template, which exclusively leverages semver ordering to generate an opinonated upgrade graph.
{{% /alert %}}

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

#### basic
Adding a new `testoperator.v0.1.1` bundle version edge with a replaces link to its predecessor `testoperator.v0.1.0` version which already exists in the channel.

```bash
yq eval 'select(.schema == "olm.template.basic").entries[] |= select(.schema == "olm.channel" and .name == "stable").entries += [{"name" : "testoperator:v0.1.1", "replaces": "testoperator:v0.1.0"}]' basic.yaml
```

produces updated `stable` channel:

```yaml
...
  - schema: olm.channel
    package: testoperator
    name: stable
    entries:
      - name: testoperator.v0.1.0
      - name: testoperator.v0.2.0
        replaces: testoperator.v0.1.0
      - name: testoperator:v0.1.1
        replaces: testoperator:v0.1.0
...
```


### Removing a specific bundle version
{{% alert title="Note" color="info" %}}
This operation is not possible for the semver template, which exclusively leverages semver ordering to generate an opinonated upgrade graph.
{{% /alert %}}

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
{{% alert title="Warning" color="warning" %}}
Please note that removing the only edge for a channel as in this example will yield an explicitly empty array.  This will produce an error in `opm validate`. 
{{% /alert %}}

#### basic
Remove the upgrade edge from the example `stable` channel which refers to bundle version `testoperator.v0.2.0`.

```bash
yq eval 'select(.schema == "olm.template.basic").entries[] |= del(select(.schema == "olm.channel" and .name == "stable").entries[]| select(.name == "testoperator.v0.2.0"))' basic.yaml
```

produces updated `stable` channel:

```yaml
...
  - schema: olm.channel
    package: testoperator
    name: stable
    entries:
      - name: testoperator.v0.1.0
...
```

### Substituting a bundle version in the upgrade graph

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

#### basic
For all channels, replace instances of `testoperator:v0.1.0` with `testoperator:v0.1.0-CVE`

```bash
yq '(..| select(. == "testoperator.v0.1.0")) |="testoperator.v0.1.0-CVE"' basic.yaml
```

produces updated channels:

```yaml
...
  - schema: olm.channel
    package: testoperator
    name: stable
    entries:
      - name: testoperator.v0.1.0-CVE
      - name: testoperator.v0.2.0
        replaces: testoperator.v0.1.0-CVE
...
```

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



### Introducing a new replacement relationship in the upgrade graph
{{% alert title="Note" color="info" %}}
This operation is not possible for the semver template, which exclusively leverages semver ordering to generate an opinonated upgrade graph.
{{% /alert %}}

#### FBC
Substitute an existing 'replaces' link target for `testoperator.v1.1.0` with a different bundle version `testoperator.v1.0.0`.


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

#### basic
Substitute an existing 'replaces' link target for `testoperator.v0.2.0` with a different bundle version `testoperator.v0.1.5`.

```bash
yq eval '.entries[] |= select(.schema == "olm.channel" and .name == "stable").entries |= [{"name" : "testoperator:v0.2.0", "replaces": "testoperator:v0.1.5"}]' basic.yaml
```
produces updated `stable` channel:

```yaml
...
  - schema: olm.channel
    package: testoperator
    name: stable
    entries:
      - name: testoperator:v0.2.0
        replaces: testoperator:v0.1.5
...
```





[file-based-catalog-spec]: /docs/reference/file-based-catalogs
[templates-doc]: /docs/reference/catalog-templates
[basic-template-doc]: /docs/reference/catalog-templates#basic-template
[semver-template-doc]: /docs/reference/catalog-templates#semver-template
[yq]: https://github.com/mikefarah/yq
