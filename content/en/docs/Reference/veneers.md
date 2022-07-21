---
title: "Veneers"
linkTitle: "Veneers (alpha)"
weight: 5
date: 2022-06-30
---

>Note: `veneers` are **ALPHA** functionality and may adopt breaking changes


## Concept and Design

File-Based Catalogs (FBC) are a major improvement to the imperative update graph approaches of previous versions. FBCs give operator authors a [declarative and deterministic approach to defining their update graph](https://olm.operatorframework.io/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/). However, FBCs can get complex, especially as the number of releases and dependencies scale. We introduce the concept of a `veneer` as an approach to simplifying interacting with FBCs.

In this context, there are two components to every `veneer`:
1. An arbitrary API
2. An executable which processes #1 and produces a valid FBC.

The veneers supported by [`opm`](https://github.com/operator-framework/operator-registry/blob/master/docs/design/opm-tooling.md) are:
- the [`basic veneer`](#basic-veneer), which provides a simplified abstraction of an FBC; and
- the [`semver veneer`](#semver-veneer), which provides the capability to generate an entire upgrade graph

## Basic Veneer
The `basic veneer` is an input schema which eliminates FBC information that can be retrieved from existing registries when we process it.
Users provide all components of an [FBC schema](https://olm.operatorframework.io/docs/reference/file-based-catalogs/#olm-defined-schemas), but supply only the bundle image reference for any `olm.bundle` objects. This results in a greatly simplified, smaller document.
This approach may be attractive to operator authors who maintain existing catalogs and just want to make the job easier, or for operator authors who need to retain a channel graph which is not based on `semver`.

### Usage

```sh
opm alpha render-veneer basic [flags] <filename>
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


Using the `opm alpha render-veneer basic` command on this input generates the full FBC:<details><summary> (click here to display full output)</summary>

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

## Semver Veneer

Since a `veneer` is identified as an input schema which is processed to generate a valid FBC, we can define a `semver veneer` as a schema which uses channel conventions to facilitate the auto-generation of channels adhering to [Semantic Versioning](https://semver.org/) (semver) guidelines and consistent with best practices on [channel naming](/docs/best-practices/channel-naming/#naming). This approach may be attractive to operator authors who are defining a new upgrade graph, or are already close enough to the veneer conventions to be able to adopt it (i.e. already use semver, only promote a single channel, etc.).

>**DISCLAIMER:** since version build metadata [MUST be ignored when determining version precedence](https://semver.org/#spec-item-10) when using semver, it cannot be used in any bundle included in the `semver veneer` and will result in a fatal error.

This alpha version of the `semver veneer` has the following goals:
- terse grammar to minimize creation/maintenance effort
- idempotent output
- simple channel promotion
- demonstration of a common type of channel maturity model
- minor-version (Y-stream) and major-version (X-stream) versioning capabilities
- clear mapping between input schema and output FBC attributes

### Specification
Like best practices [recommended channel naming](/docs/best-practices/channel-naming/#recommended-channel-naming), this veneer supports channel names `Candidate`, `Fast`, and `Stable`, in order of increasing channel stability. We leverage this relationship when calculating the default channel for the package. 

`GenerateMajorChannels` and `GenerateMinorChannels` dictate whether this veneer will generate X-stream or Y-stream channels (attributes can be set independently). If omitted, only minor (Y-stream) channels will be generated. 

Under each channel are a list of bundle image references which contribute to that channel. At least one channel must have bundle images.

The `olm.semver` [cue](https://cuelang.org/docs/references/spec/) schema is:

```cue
#Package: {
  schema: "olm.semver"

  // optional flag to control generating minor-version channels, defaults to _true_ if unspecified
  GenerateMinorChannels?: bool

  // optional flag to control generating major-version channels, defaults to _false_ if unspecified
  GenerateMajorChannels?: bool

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
opm alpha render-veneer semver [flags] <filename>
```


| Flag                | Description                                                                            |
| ------------------- | -------------------------------------------------------------------------------------- |
| -h, --help          | prints help/usage information                                                          |
| -o, --output <type> | the output format, can be `yaml` or `json`                                             |
| --skip-tls-verify   | skip TLS certificate verification for container image registries while pulling bundles |
| --use-http          | use plain HTTP for container image registries while pulling bundles                    |

`--skip-tls-verify` and `--use-http` are mutually exclusive flags.

### Example 

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

If we set the veneer attributes 

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

We generated a channel for each veneer channel entity corresponding to each of the 0.\#.\#, 1.\#.\# major version ranges with skips to the head of the highest semver in a channel. We also generated a replaces edge to traverse across minor version transitions within each major channel. Finally, we generated an `olm.package` object, setting as default the most-stable channel head we created. This process will prefer `Stable` channel over `Fast`, over `Candidate` and then a higher bundle version over a lower version.  
(Please note that the naming of the generated channels indicates the digits of significance for that channel. For example, `fast-v1` is a decomposed channel of the `fast` type which contains only major versions of contributing bundles matching `v1`.)  

For contrast, if we set the veneer attributes

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

Here, a channel is generated for each veneer channel which differs by minor version, and each channel has a `replaces` edge from the predecessor channel to the next-lesser minor bundle version. Please note that at no time do we transgress across major-version boundaries with the channels, to be consistent with [the semver convention](https://semver.org/) for major versions, where the purpose is to make incompatible API changes.

