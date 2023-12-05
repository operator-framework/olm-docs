---
title: "Catalog Templates"
linkTitle: "Catalog Templates (alpha)"
weight: 5
date: 2022-06-30
---

>Note: `catalog templates` are **ALPHA** functionality and may adopt breaking changes


## Concept and Design

File-Based Catalogs (FBC) are a major improvement to the imperative update graph approaches of previous versions. FBCs give operator authors a [declarative and deterministic approach to defining their update graph](https://olm.operatorframework.io/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/). However, FBCs can get complex, especially as the number of releases and dependencies scale. We introduce the concept of a `catalog template` (referred to as `template` going forward) as an approach to simplifying interacting with FBCs.

In this context, there are two components to every `template`:
1. An arbitrary API
2. An executable which processes #1 and produces a valid FBC.

The templates supported by [`opm`](https://github.com/operator-framework/operator-registry/blob/master/docs/design/opm-tooling.md) are:
- the [`basic template`](#basic-template), which provides a simplified abstraction of an FBC
- the [`semver template`](#semver-template), which provides the capability to generate an entire upgrade graph
- the [`composite template`](#composite-template), which provides the capability to generate an FBC contribution for multiple catalogs

## Basic Template
The `basic template` is an input schema which eliminates FBC information that can be retrieved from existing registries when we process it.
Users provide all components of an [FBC schema](https://olm.operatorframework.io/docs/reference/file-based-catalogs/#olm-defined-schemas), but supply only the bundle image reference for any `olm.bundle` objects. This results in a greatly simplified, smaller document.
This approach may be attractive to operator authors who maintain existing catalogs and just want to make the job easier, or for operator authors who need to retain a channel graph which is not based on `semver`.

### Usage

```sh
opm alpha render-template basic [flags] <filename>
```


| Flag                | Description                                                                            |
| ------------------- | -------------------------------------------------------------------------------------- |
| -h, --help          | prints help/usage information                                                          |
| -o, --output <type> | the output format, can be `yaml` or `json`                                             |
| --skip-tls-verify   | skip TLS certificate verification for container image registries while pulling bundles |
| --use-http          | use plain HTTP for container image registries while pulling bundles                    |

`--skip-tls-verify` and `--use-http` are mutually exclusive flags.

### Example

In a very simple example, we define an `olm.package` and an `olm.channel` composed of two `olm.bundle` objects that have an image name attribute but no other attributes/properties.
```yaml
---
schema: olm.package
name: example-operator
defaultChannel: stable
---
schema: olm.channel
package: example-operator
name: stable
entries:
- name: example-operator.v0.1.0
- name: example-operator.v0.2.0
  replaces: example-operator.v0.1.0
---
schema: olm.bundle
image: docker.io/example/example-operator-bundle:0.1.0
---
schema: olm.bundle
image: docker.io/example-operator-bundle:0.2.0
```


Using the `opm alpha render-template basic` command on this input generates the full FBC:<details><summary> (click here to display full output)</summary>

(data blobs truncated with '... [snip] ...' for brevity)

```yaml
---
defaultChannel: stable
name: example-operator
schema: olm.package
---
entries:
- name: example-operator.v0.1.0
- name: example-operator.v0.2.0
  replaces: example-operator.v0.1.0
name: stable
package: example-operator
schema: olm.channel
---
image: docker.io/example/example-operator-bundle:0.1.0
name: example-operator.v0.1.0
package: example-operator
properties:
- type: olm.gvk
  value:
    group: example.com
    kind: App
    version: v1
- type: olm.package
  value:
    packageName: example-operator
    version: 0.1.0
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW9uIjoidjEiLCJraW5kIjoiU2VydmljZSIsIm1ldGFkYXRhIjp7ImNyZWF0aW9uVGltZXN0YW1wIjpudWxsLCJsYWJlbHMiOnsiY29udHJvbC1wbGFuZSI6ImNvbnRyb2xsZXItbWFuYWdlciJ9LCJuYW1lIjoiZXhhbXBsZS1vcGVyYXRvci1jb250cm9sbGVyLW1hbmFnZXItbWV0cmljcy1zZXJ2aWNlIn0sInNwZWMiOnsicG9ydHMiOlt7Im5hbWUiOiJodHRwcyIsInBvcnQiOjg0NDMsInByb3RvY29sIjoiVENQIiwidGFyZ2V0UG9ydCI6Imh0dHBzIn1dLCJzZWxlY3RvciI6eyJjb250cm9sLXBsYW5lIjoiY29udHJvbGxlci1tYW5hZ2VyIn19LCJzdGF0dXMiOnsibG9hZEJhbGFuY2VyIjp7fX19
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW9uIjoidjEiLCJkYXRhIjp7ImNvbnRyb2xsZXJfbWFuYWdlcl9jb25maWcueWFtbCI6ImFwaVZlcnNpb246IGNvbnRyb2xsZXItcnVudGltZS5zaWdzLms4cy5pby92MWFscGhhMVxua2luZDogQ29udHJvbGxlck1hbmFnZXJDb25maWdcbmhlYWx0aDpcbiAgaGVhbHRoUHJvYmVCaW5kQWRkcmVzczogOjgwODFcbm1ldHJpY3M6XG4gIGJpbmRBZGRyZXNzOiAxMjcuMC4wLjE6ODA4MFxud2ViaG9vazpcbiAgcG9ydDogOTQ0M1xubGVhZGVyRWxlY3Rpb246XG4gIGxlYWRlckVsZWN0OiB0cnVlXG4gIHJlc291cmNlTmFtZTogY2RmNjA0MTIuY29tXG4ifSwia2luZCI6IkNvbmZpZ01hcCIsIm1ldGFkYXRhIjp7Im5hbWUiOiJleGFtcGxlLW9wZXJhdG9yLW1hbmFnZXItY29uZmlnIn19
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW9uIjoicmJhYy5hdXRob3JpemF0aW9uLms4cy5pby92MSIsImtpbmQiOiJDbHVzdGVyUm9sZSIsIm1ldGFkYXRhIjp7ImNyZWF0aW9uVGltZXN0YW1wIjpudWxsLCJuYW1lIjoiZXhhbXBsZS1vcGVyYXRvci1tZXRyaWNzLXJlYWRlciJ9LCJydWxlcyI6W3sibm9uUmVzb3VyY2VVUkxzIjpbIi9tZXRyaWNzIl0sInZlcmJzIjpbImdldCJdfV19
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW ... [snip] ... jEuMCJ9fQ==
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW ... [snip] ... jEuMCJ9fQ==
relatedImages:
- image: gcr.io/kubebuilder/kube-rbac-proxy:v0.8.0
  name: ""
- image: docker.io/example/example-operator-bundle:0.1.0
  name: ""
- image: docker.io/example/example-operator:0.1.0
  name: ""
schema: olm.bundle
---
image: docker.io/example/example-operator-bundle:0.2.0
name: example-operator.v0.2.0
package: example-operator
properties:
- type: olm.gvk
  value:
    group: example.com
    kind: App
    version: v1
- type: olm.package
  value:
    packageName: example-operator
    version: 0.2.0
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW9uIjoidjEiLCJraW5kIjoiU2VydmljZSIsIm1ldGFkYXRhIjp7ImNyZWF0aW9uVGltZXN0YW1wIjpudWxsLCJsYWJlbHMiOnsiY29udHJvbC1wbGFuZSI6ImNvbnRyb2xsZXItbWFuYWdlciJ9LCJuYW1lIjoiZXhhbXBsZS1vcGVyYXRvci1jb250cm9sbGVyLW1hbmFnZXItbWV0cmljcy1zZXJ2aWNlIn0sInNwZWMiOnsicG9ydHMiOlt7Im5hbWUiOiJodHRwcyIsInBvcnQiOjg0NDMsInByb3RvY29sIjoiVENQIiwidGFyZ2V0UG9ydCI6Imh0dHBzIn1dLCJzZWxlY3RvciI6eyJjb250cm9sLXBsYW5lIjoiY29udHJvbGxlci1tYW5hZ2VyIn19LCJzdGF0dXMiOnsibG9hZEJhbGFuY2VyIjp7fX19
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW9uIjoidjEiLCJkYXRhIjp7ImNvbnRyb2xsZXJfbWFuYWdlcl9jb25maWcueWFtbCI6ImFwaVZlcnNpb246IGNvbnRyb2xsZXItcnVudGltZS5zaWdzLms4cy5pby92MWFscGhhMVxua2luZDogQ29udHJvbGxlck1hbmFnZXJDb25maWdcbmhlYWx0aDpcbiAgaGVhbHRoUHJvYmVCaW5kQWRkcmVzczogOjgwODFcbm1ldHJpY3M6XG4gIGJpbmRBZGRyZXNzOiAxMjcuMC4wLjE6ODA4MFxud2ViaG9vazpcbiAgcG9ydDogOTQ0M1xubGVhZGVyRWxlY3Rpb246XG4gIGxlYWRlckVsZWN0OiB0cnVlXG4gIHJlc291cmNlTmFtZTogY2RmNjA0MTIuY29tXG4ifSwia2luZCI6IkNvbmZpZ01hcCIsIm1ldGFkYXRhIjp7Im5hbWUiOiJleGFtcGxlLW9wZXJhdG9yLW1hbmFnZXItY29uZmlnIn19
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW9uIjoicmJhYy5hdXRob3JpemF0aW9uLms4cy5pby92MSIsImtpbmQiOiJDbHVzdGVyUm9sZSIsIm1ldGFkYXRhIjp7ImNyZWF0aW9uVGltZXN0YW1wIjpudWxsLCJuYW1lIjoiZXhhbXBsZS1vcGVyYXRvci1tZXRyaWNzLXJlYWRlciJ9LCJydWxlcyI6W3sibm9uUmVzb3VyY2VVUkxzIjpbIi9tZXRyaWNzIl0sInZlcmJzIjpbImdldCJdfV19
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW ... [snip] ... jEuMCJ9fQ==
- type: olm.bundle.object
  value:
    data: eyJhcGlWZXJzaW ... [snip] ... jEuMCJ9fQ==
relatedImages:
- image: gcr.io/kubebuilder/kube-rbac-proxy:v0.8.0
  name: ""
- image: docker.io/example/example-operator-bundle:0.2.0
  name: ""
- image: docker.io/example/example-operator:0.2.0
  name: ""
schema: olm.bundle

```
</details>

#### Converting from FBC to Basic Template
Operator authors can convert a File-Based Catalog (FBC) to a basic template by processing the output of the `opm render` command through either `jq` or `yq`.

To convert a File-Based Catalog to a Basic Template using `jq`, run the following command:

```sh
opm render <catalogRef> -o json | jq 'if (.schema == "olm.bundle") then {schema: .schema, image: .image} else . end'
```

Example template in JSON format after the conversion:

```json
{
  "schema": "olm.package",
  "name": "hello-kubernetes",
  "defaultChannel": "alpha",
  "description": "hello-kubernetes"
}
{
  "schema": "olm.channel",
  "name": "alpha",
  "package": "hello-kubernetes",
  "entries": [
    {
      "name": "hello-kubernetes.v0.0.1"
    }
  ]
}
{
  "schema": "olm.bundle",
  "image": "docker.io/test/hello-kubernetes-operator-bundle:v0.0.1"
}
```

To convert a File-Based Catalog to a Basic Template using `yq`, run the following command:

```sh
opm render <catalogRef> -o yaml | yq eval -i 'select(.schema == "olm.bundle") = {"schema": .schema, "image": .image}' test.yaml - test.yaml
```

Example basic template in YAML format after the conversion:

```yaml
  ---
  schema: olm.package
  defaultChannel: alpha
  description: hello-kubernetes
  name: hello-kubernetes
  ---
  schema: olm.channel
  name: alpha
  package: hello-kubernetes
  entries:
    - name: hello-kubernetes.v0.0.1
  ---
  schema: olm.bundle
  image: docker.io/test/hello-kubernetes-operator-bundle:v0.0.1
```

## Semver Template

Since a `catalog template` is identified as an input schema which is processed to generate a valid FBC, we can define a `semver template` as a schema which uses channel conventions to facilitate the auto-generation of channels adhering to [Semantic Versioning](https://semver.org/) (semver) guidelines and consistent with best practices on [channel naming](/docs/best-practices/channel-naming/#naming). This approach may be attractive to operator authors who are defining a new upgrade graph, or are already close enough to this template's conventions to be able to adopt it.

>**DISCLAIMER:** since version build metadata MUST be ignored when determining version precedence (see [spec #10](https://semver.org/)) when using semver, if any bundles differ only by build metadata the render attempt will generate a fatal error.

This alpha version of the `semver template` has the following goals:
- terse grammar to minimize creation/maintenance effort
- idempotent output
- simple channel promotion
- demonstration of a common type of channel maturity model
- minor-version (Y-stream) and major-version (X-stream) versioning capabilities
- clear mapping between input schema and output FBC attributes

>**Note:** The semver template depends on the optional `csv.spec.version` field. If you want to use the semver catalog template, you must specify a version in your extension's CSV.

### Specification
Like best practices [recommended channel naming](/docs/best-practices/channel-naming/#recommended-channel-naming), this template supports channel names `Candidate`, `Fast`, and `Stable`, in order of increasing channel stability. We leverage this relationship when calculating the default channel for the package. 

`GenerateMajorChannels` and `GenerateMinorChannels` dictate whether this template will generate X-stream or Y-stream channels (attributes can be set independently). If omitted, only minor (Y-stream) channels will be generated. 

Under each channel are a list of bundle image references which contribute to that channel. At least one channel must have bundle images.

The `olm.semver` [cue](https://cuelang.org/docs/references/spec/) schema is:

```cue
#Package: {
  schema: "olm.semver"

  // optional flag to control generating minor-version channels, defaults to _true_ if unspecified
  GenerateMinorChannels?: bool

  // optional flag to control generating major-version channels, defaults to _false_ if unspecified
  GenerateMajorChannels?: bool

  // optional preference for major- or minor-version channels, when both are generated and identical in stability and version
  DefaultChannelTypePreference?: string

  // optional candidate channel
  Candidate?: {
    Bundles: [...#ImageEntry]
  }

  // optional fast channel
  Fast?: {
    Bundles: [...#ImageEntry]
  }

  // optional stable channel
  Stable?: {
    Bundles: [...#ImageEntry]
  }

  #ImageEntry: {
    Image: string
  }
}
```

### Usage

```sh
opm alpha render-template semver [flags] <filename>
```


| Flag                | Description                                                                            |
| ------------------- | -------------------------------------------------------------------------------------- |
| -h, --help          | prints help/usage information                                                          |
| -o, --output <type> | the output format, can be `yaml` or `json`                                             |
| --skip-tls-verify   | skip TLS certificate verification for container image registries while pulling bundles |
| --use-http          | use plain HTTP for container image registries while pulling bundles                    |

`--skip-tls-verify` and `--use-http` are mutually exclusive flags.

### Examples 

With the following (hypothetical) example we define a mock bundle which has 11 versions, represented across each of the channel types:

```yaml
Schema: olm.semver
GenerateMajorChannels: true
GenerateMinorChannels: true
Candidate:
  Bundles:
  - Image: quay.io/foo/olm:testoperator.v0.1.0
  - Image: quay.io/foo/olm:testoperator.v0.1.1
  - Image: quay.io/foo/olm:testoperator.v0.1.2
  - Image: quay.io/foo/olm:testoperator.v0.1.3
  - Image: quay.io/foo/olm:testoperator.v0.2.0
  - Image: quay.io/foo/olm:testoperator.v0.2.1
  - Image: quay.io/foo/olm:testoperator.v0.2.2
  - Image: quay.io/foo/olm:testoperator.v0.3.0
  - Image: quay.io/foo/olm:testoperator.v1.0.0
  - Image: quay.io/foo/olm:testoperator.v1.0.1
  - Image: quay.io/foo/olm:testoperator.v1.1.0
Fast:
  Bundles:
  - Image: quay.io/foo/olm:testoperator.v0.2.1
  - Image: quay.io/foo/olm:testoperator.v0.2.2
  - Image: quay.io/foo/olm:testoperator.v0.3.0
  - Image: quay.io/foo/olm:testoperator.v1.0.1
  - Image: quay.io/foo/olm:testoperator.v1.1.0
Stable:
  Bundles:
  - Image: quay.io/foo/olm:testoperator.v1.0.1
```

In this example, `Candidate` has the entire version range of bundles,  `Fast` has a mix of older and more-recent versions, and `Stable` channel only has a single published entry. 

#### Generating major-version channels

If we set the template attributes 

```yaml 
GenerateMajorChannels: true
GenerateMinorChannels: false
```

we generate the following major channels (filtering out `olm.bundle` objects):
```yaml
---
defaultChannel: stable-v1
name: testoperator
schema: olm.package
---
entries:
- name: testoperator.v0.1.0
- name: testoperator.v0.1.1
- name: testoperator.v0.1.2
- name: testoperator.v0.1.3
  skips:
  - testoperator.v0.1.0
  - testoperator.v0.1.1
  - testoperator.v0.1.2
- name: testoperator.v0.2.0
- name: testoperator.v0.2.1
- name: testoperator.v0.2.2
  replaces: testoperator.v0.1.3
  skips:
  - testoperator.v0.2.0
  - testoperator.v0.2.1
- name: testoperator.v0.3.0
  replaces: testoperator.v0.2.2
name: candidate-v0
package: testoperator
schema: olm.channel
---
entries:
- name: testoperator.v1.0.0
- name: testoperator.v1.0.1
  skips:
  - testoperator.v1.0.0
- name: testoperator.v1.1.0
  replaces: testoperator.v1.0.1
name: candidate-v1
package: testoperator
schema: olm.channel
---
entries:
- name: testoperator.v0.2.1
- name: testoperator.v0.2.2
  skips:
  - testoperator.v0.2.1
- name: testoperator.v0.3.0
  replaces: testoperator.v0.2.2
name: fast-v0
package: testoperator
schema: olm.channel
---
entries:
- name: testoperator.v1.0.1
- name: testoperator.v1.1.0
  replaces: testoperator.v1.0.1
name: fast-v1
package: testoperator
schema: olm.channel
---
entries:
- name: testoperator.v1.0.1
name: stable-v1
package: testoperator
schema: olm.channel
```

We generated a channel for each template channel entity corresponding to each of the 0.\#.\#, 1.\#.\# major version ranges with skips to the head of the highest semver in a channel. We also generated a replaces edge to traverse across minor version transitions within each major channel. Finally, we generated an `olm.package` object, setting as default the most-stable channel head we created. This process will prefer `Stable` channel over `Fast`, over `Candidate` and then a higher bundle version over a lower version.  
(Please note that the naming of the generated channels indicates the digits of significance for that channel. For example, `fast-v1` is a decomposed channel of the `fast` type which contains only major versions of contributing bundles matching `v1`.)  

#### Generating minor-version channels

For contrast, if we set the template attributes

```yaml
GenerateMinorChannels: true
GenerateMajorChannels: false
```

 we generate the following minor channels (again filtering out `olm.bundle` objects):

```yaml
---
defaultChannel: stable-v1.0
name: testoperator
schema: olm.package
---
entries:
  - name: testoperator.v0.1.0
  - name: testoperator.v0.1.1
  - name: testoperator.v0.1.2
  - name: testoperator.v0.1.3
    skips:
      - testoperator.v0.1.0
      - testoperator.v0.1.1
      - testoperator.v0.1.2
name: candidate-v0.1
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v0.2.0
  - name: testoperator.v0.2.1
  - name: testoperator.v0.2.2
    replaces: testoperator.v0.1.3
    skips:
      - testoperator.v0.2.0
      - testoperator.v0.2.1
name: candidate-v0.2
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v0.3.0
    replaces: testoperator.v0.2.2
name: candidate-v0.3
package: testoperator
schema: olm.channel
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
name: candidate-v1.1
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v0.2.1
  - name: testoperator.v0.2.2
    skips:
      - testoperator.v0.2.1
name: fast-v0.2
package: testoperator
schema: olm.channel
---
entries:
  - name: testoperator.v0.3.0
    replaces: testoperator.v0.2.2
name: fast-v0.3
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

Here, a channel is generated for each template channel which differs by minor version, and each channel has a `replaces` edge from the predecessor channel to the next-lesser minor bundle version. Please note that at no time do we transgress across major-version boundaries with the channels, to be consistent with [the semver convention](https://semver.org/) for major versions, where the purpose is to make incompatible API changes.

#### Generating both channel types, and disambiguating default channel selection

In the case that we generate both major-version and minor-version channels:

```yaml
GenerateMinorChannels: true
GenerateMajorChannels: true
```

we can easily end up in a situation where our results yield indifferentiable results, for e.g.:

```yaml
---
entries:
- name: testoperator.v1.0.1
name: stable-v1
package: testoperator
schema: olm.channel
---
entries:
- name: testoperator.v1.0.1
name: stable-v1.0
package: testoperator
schema: olm.channel
```

In this situation, both channels have matching channel archetypes and the channel heads have the same versions.  The `DefaultChannelTypePreference` attribute allows us to deterministically select a single channel in this case.  This attribute defaults to prefer minor-version channels (`DefaultChannelTypePreference: minor`), but can be overridden in the schema if the author wishes to prefer major-version channels instead (`DefaultChannelTypePreference: major`). 

With `DefaultChannelTypePreference` set to `major`, our most-stable channels and package output would look like
```yaml
---
defaultChannel: stable-v1
name: testoperator
schema: olm.package
---
entries:
- name: testoperator.v1.0.1
name: stable-v1
package: testoperator
schema: olm.channel
---
entries:
- name: testoperator.v1.0.1
name: stable-v1.0
package: testoperator
schema: olm.channel
```

## Composite Template
A `composite template` can help an operator author manage FBC contributions to multiple catalogs. The template functionality is composed of schemas which represent the author's role and the catalog maintainer's role, and rendering the template performs an explicit negotiation between them.

### Usage
```sh
opm alpha render-template composite [flags]
```

| Flag                | Description                                                                            |
| ------------------- | -------------------------------------------------------------------------------------- |
| -f, --catalog-config string | File to use as the catalog configuration file (default "catalogs.yaml")        |
| -c, --composite-config string | File to use as the composite configuration file (default "catalog/config.yaml") |
| -h, --help          | help for composite                                                                     |
| -o, --output string | Output format (json|yaml) (default "json")                                             |
| --validate          | whether or not the created FBC should be validated (i.e 'opm validate') (default true) |
| --skip-tls-verify   | skip TLS certificate verification for container image registries while pulling bundles |
| --use-http          | use plain HTTP for container image registries while pulling bundles                    |




### Specifications
The `composite template` is composed of two schemas that represent the operator author's role and the catalog maintainer's role, fulfilled by `olm.composite` and `olm.composite.catalogs`, respectively.

#### olm.composite
The `olm.composite` schema represents the operator author role and defines the following:
- Where each input (`Component`) exists
- How each `Component` is mapped to a destination catalog (`Component.Name`). All destination catalogs defined in this file **must** also exist in the catalog configuration file created by the catalog maintainers
- How each `Component` is processed to generate a catalog contribution (`Component.Strategy`)
- The directory structure the catalog contribution generation should follow (`Component.Destination`)

The cue schema for the `olm.composite` schema is:
```cue
#CompositeConfig: {
	Schema: "olm.composite"
	Components: [...#Component]
}

#Component: {
	Name:        string
	Destination: #ComponentDestination
	Strategy:  #BuildStrategy
}

#ComponentDestination {
	Path: string
}

#BuildStrategy: {
	Name:   string
	Template: #TemplateDefinition
}

#TemplateDefinition: {
	Schema: string
}
```

#### olm.composite.catalogs
The `olm.composite.catalogs` schema represents the catalog maintainer role and defines the following:
- One or more catalogs (`Catalog`) identified by a string (`Catalog.Name`)
- Supported input formats (`Builder`) for each `Catalog` (`Catalog.Builders`) which is a list of strings where each item is a `Builder` schema. The currently supported `Builder` schemas are:
    - `olm.builder.basic` which represents that the use of [basic templates](#basic-template) for catalog contribution generation is allowed
    - `olm.builder.semver` which represents that the use of [semver templates](#semver-template) for catalog contribution generation is allowed
- The expected directory structure of any generated contribution (`Catalog.Destination.WorkingDir`)

The cue schema for the `olm.composite.catalogs` schema is:
```cue
#CatalogConfig: {
	Schema: "olm.composite.catalogs"
	Catalogs: [... #Catalog]
}

#Catalog: {
	Name:        string
	Destination: #CatalogDestination
	Builders: [...string]
}

#CatalogDestination: {
	BaseImage:  string
	WorkingDir: string
}
```

### Example
**catalogs.yaml**

The following example specifies a catalog configuration that defines a catalog named `v1`. This example limits the input to the [semver template](#semver-template) for contribution generation logic. If you use the `opm alpha render-template composite` subcommand the path to this file can be specified with the `-f` option. This option can be a file path or a URL. If you use a URL, the URL must return the raw file contents.

```yaml
schema: olm.composite.catalogs
catalogs:
- name: v1 {{< code_callout 1 >}}
  destination:
    baseImage: quay.io/operator-framework/opm:v1.24
    workingDir: catalogs/v1 {{< code_callout 2 >}}
  builders:
    - olm.builder.semver {{< code_callout 3 >}}
```

- {{< code_callout 1 >}} Defines the `v1` catalog configuration
- {{< code_callout 2 >}} Defines the directory path that all output should be placed for this catalog. In this example, when rendering using the composite catalog all output for the `v1` catalog will be put under the `catalogs/v1/` directory
- {{< code_callout 3 >}} Defines the allowed builders for the `v1` catalog. In this example the semver builder is the only builder allowed. As a result, this catalog renders only [semver templates](#semver-template) as contributions

**contributions.yaml**

The following example specifies a composite template configuration that defines the input, build process, and output of a catalog contribution for the `v1` catalog.

```yaml
schema: olm.composite
components:
- name: v1 {{< code_callout 1 >}}
  destination:
    path: my-package {{< code_callout 2 >}}
  strategy:
    name: basic
    template:
      schema: olm.builder.semver {{< code_callout 3 >}}
      config:
        input: components/v1.yaml {{< code_callout 4 >}}
        output: catalog.yaml {{< code_callout 5 >}}
```

- {{< code_callout 1 >}} Defines the build process for the `v1` catalog contribution.
- {{< code_callout 2 >}} Defines the name of the package being contributed and is used to create the package directory
- {{< code_callout 3 >}} Specifies that the input for the `v1` catalog contribution is a [semver template](#semver-template) so that the contribution can be rendered appropriately
- {{< code_callout 4 >}} Specifies the input file that is used to generate the catalog contribution
- {{< code_callout 5 >}} Defines the name of the output file. This is joined as a path with the  `destination.path` value defined in {{< code_callout 2 >}}. In this example the full output path after rendering the template is `my-package/catalog.yaml`

When using the `opm alpha render-template composite -f catalogs.yaml -c contributions.yaml` command, the resulting output should look similar to:
```tree
catalogs
├── v1 {{< code_callout 1 >}}
│   └── my-package {{< code_callout 2 >}}
│       └── catalog.yaml {{< code_callout 3 >}}
```

- {{< code_callout 1 >}} Output directory for the `v1` catalog as specified by the example catalog configuration file
- {{< code_callout 2 >}} Output directory for our `v1` catalog contribution as specified by the example composite configuration file
- {{< code_callout 3 >}} Output file containing the rendered FBC for our contribution to the `v1` catalog 
