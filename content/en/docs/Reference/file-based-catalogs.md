---
title: "File-based Catalogs"
linkTitle: "File-based Catalogs"
weight: 4
date: 2022-01-18
---

File-based catalogs are the latest iteration of OLM's catalog format. It is a fully plaintext-based (JSON or YAML)
evolution of the previous sqlite database format that is fully backwards compatible.

## Design

The primary design goal for this format is to enable catalog editing, composability, and extensibility.

### Editing

With file-based catalogs, users interacting with the contents of a catalog are able to make direct changes to the catalog
format and verify that their changes are valid.

Because this format is plaintext JSON or YAML, catalog maintainers can easily manipulate catalog metadata by hand or with
widely known and supported JSON or YAML tooling (e.g. `jq`).

This editability enables features and user-defined extensions, such as:
- Promoting an existing bundle to a new channel
- Changing the default channel of a package
- Custom algorithms for adding, updating, adding removing upgrade edges

### Composability

File-based catalogs are stored in an arbitrary directory hierarchy, which enables catalog composition. If I have two
separate file-based catalog directories, `CatalogA` and `CatalogB`, I can make a new combined catalog by making a new
directory `CatalogC` and copying `CatalogA` and `CatalogB` into it.

This composability enables decentralized catalogs. The format permits operator authors to maintain operator-specific
catalogs and catalog maintainers to trivially build a catalog composed of individual operator-specific catalogs.

> NOTE: Duplicate packages and duplicate bundles within a package are not permitted. The `opm validate` command will
> return an error if any duplicates are found.

Since operator authors are most familiar with their operator, its dependencies, and its upgrade compatibility, they are
able to maintain their own operator-specific catalog and have direct control over its contents. With file-based catalogs,
operator authors own the task of building and maintaining their packages in a catalog. Composite catalog maintainers treat
packages as a black box; they own the task of curating the packages in their catalog and publishing the catalog to
users.

File-based catalogs can be composed by combining multiple other catalogs or by extracting subsets of one catalog, or a
combination of both of these.

See the [Building a composite catalog](#building-a-composite-catalog) section for a simple example.

### Extensibility

The final design goal is to provide extensibility around catalogs. The file-based catalog spec is a low-level
representation of a catalog. While it can be maintained directly in its low-level form, we expect many catalog maintainers
to build interesting extensions on top that can be used by their own custom tooling to make all sorts of mutations. For
example, one could imagine a tool that translates a high-level API like (mode=semver) down to the low-level file-based
catalog format for upgrade edges. Or perhaps a catalog maintainer needs to customize all of the bundle metadata by adding
a new property to bundles that meet a certain criteria.

The OLM developer community will be making use of this extensibility to build more official tooling on top of the
low-level APIs, but the major benefit is that catalog maintainers have this capability as well.

## Specification

### Structure

File-based catalogs can be stored and loaded from directory-based filesystems.

`opm` loads the catalog by walking the root directory and recursing into subdirectories. It attempts to load every file
it finds and fails if any errors occur.

Non-catalog files can be ignored using `.indexignore` files, which behave identically to `.gitignore` files. That is,
they have the same rules for [patterns](https://git-scm.com/docs/gitignore#_pattern_format) and precedence.

> **Example `.gitignore` file**
> ```gitignore
> # Ignore everything except non-object .json and .yaml files
> **/*
> !*.json
> !*.yaml
> **/objects/*.json
> **/objects/*.yaml
> ```

Catalog maintainers have the flexibility to chose their desired layout, but the OLM team recommends storing each package's
file-based catalog blobs in separate sub-directories. Each individual file can be either JSON or YAML -- it is not
necessary for every file in a catalog to use the same format.

This layout has the property that each sub-directory in the directory hierarchy is a self-contained catalog, which makes
catalog composition, discovery, and navigation as simple as trivial filesystem operations.

> **Basic recommended structure**
> ```
> catalog
> ├── pkgA
> │   └── operator.yaml
> ├── pkgB
> │   ├── .indexignore
> │   ├── operator.yaml
> │   └── objects
> │       └── pkgB.v0.1.0.clusterserviceversion.yaml
> └── pkgC
>     └── operator.json
> ```

This catalog could also be trivially included in a parent catalog by simply copying it into the parent catalog's root
directory.

### Schema

At its core, file-based catalogs use a simple format that can be extended with arbitrary schemas. The format that all
file-based catalog blobs must adhere to is the `Meta` schema, which consists of `schema`, `package`, `name`, and
`properties` fields. The `schema` field is required. The `package`, `name`, and `properties` fields are optional, but if
they are present, they must adhere to their respective field schemas. Any other field is allowed and is specified by the schema.

The combination of the `schema`, `package`, and `name` fields must be unique within a catalog.

See the [Properties](#properties) section for information about the property type.

Here is an example of an object which adheres to the `Meta` schema:

```yaml
### Core Meta fields
# The schema for this object (required)
schema: "example.com.my.object"

# The package this object belongs to, if applicable (optional)
package: foo

# The name of this object, if applicable (optional)
name: bar

# The properties associated with this object, if applicable (optional)
properties:
- type: my.string
  value: "my value"
- type: my.map
  value:
    key1: value1
    key2:
    - hello
    - world
    key3:
      harry: sally
- type: my.list
  value:
    - item1
    - item2

# (schema: "my.other.object")-defined, non-meta fields
myCustomMap:
  whiz: bang
myCustomList:
  - alice
  - bob
```

When this blob is parsed as a `Meta` object, the core fields are parsed to their respective types. Non-meta fields
are not parsed. However, the parsed `Meta` object contains the full JSON representation of the blob, which enables
callers to parse the object using a more specific type that maps to the "my.other.object" schema.


### OLM-defined schemas

An OLM catalog currently uses three schemas: `olm.package`, `olm.channel`, and `olm.bundle`, which correspond to OLM's
existing package, channel, and bundle concepts.

Each operator package in a catalog requires exactly one `olm.package` blob, at least one `olm.channel` blob, and one or
more `olm.bundle` blobs.

> **NOTE**: All `olm.*` schemas are reserved for OLM-defined schemas. Custom schemas must use a unique prefix (e.g. a
> domain that you own).

#### `olm.package`

An `olm.package` defines package-level metadata for an operator. This includes its name, description, default channel
and icon.

Here is an example of an `olm.package` blob:

```yaml
schema: olm.package
name: foo

# Description is markdown-formatted text that describes the operator.
# It may contain overviews, installation instructions, links, migration
# guides, etc. It is meant for a human audience.
description: |-
  foo-operator is a Kubernetes operator to deploy and manage Foo resources for a Kubernetes cluster.

  ## Overview

  Foo is a service that orchestrates Bar and Baz to provide a simple integrated experience.

  The goal of the **foo-operator** is to make it easy to orchestrate complex tasks that underpin the Foo
  service, including Bar and Baz upgrades, migrations, and optimizations.

# DefaultChannel is the name of the default channel for this package.
defaultChannel: candidate-v0

# Icon defines the image that UIs can use to represent this package.
icon:
  base64data: PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz4KPHN2ZyB2ZXJzaW9uPSIxLjEiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgdmlld0JveD0iMCAwIDMyMCAzMjAiPgogIDxnIGlkPSJsb2dvIiBmaWxsPSIjZmZmIj4KICAgIDxjaXJjbGUgY3g9IjE2MCIgY3k9IjE2MCIgcj0iMTAwIiBzdHJva2U9InBpbmsiIHN0cm9rZS13aWR0aD0iMyIgZmlsbD0icmVkIiAvPgogIDwvZz4KPC9zdmc+Cg==
  mediatype: image/svg+xml
```

#### `olm.channel`

An `olm.channel` defines a channel within a package, the bundle entries that are members
of the channel, and the upgrade edges for those bundles.

A bundle can be included as an entry in multiple `olm.channel` blobs, but it can have only one entry per channel.

Also, it is valid for an entry's replaces value to reference another bundle name that cannot be found in this catalog
(or even another catalog) as long as other channel invariants still hold (e.g. a channel cannot have multiple heads).

Here is an example of an `olm.channel` blob:
```yaml
schema: olm.channel
package: foo
name: candidate-v0
entries:
- # name is required. It is the name of an `olm.bundle` that
  # is present in the channel.  
  name: foo.v0.3.1
  
  # replaces is optional. It is the name of the bundle that is replaced
  # by this entry. It must be present in the entry list, unless this
  # entry is the channel tail. Channel tails are allowed to have replaces
  # values that are not present in the entry list.
  replaces: foo.v0.2.1
  
  # skips is optional. It is a list of bundle names that are skipped by
  # this entry. The skipped bundles do not have to be present in the
  # entry list.
  skips:
  - foo.v0.3.0

  # skipRange is optional. It is the semver range of bundle versions
  # that are skipped by this entry.
  skipRange: ">=0.2.0-0 <0.3.1-0"
  
- name: foo.v0.3.0
  replaces: v0.2.1
- name: foo.v0.2.1
```

For more information about defining upgrade edges, see the [upgrade graph reference documentation][upgrade-graph-doc].

[upgrade-graph-doc]: /docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph

#### `olm.bundle`

An `olm.bundle` defines an individually installable version of an operator within a package. It contains information
necessary to locate the bundle's contents, the related images used by the operator at runtime, and properties that
can be used by clients to orchestrate lifecycling behavior, build user interfaces, provide filtering mechanisms, etc.
For example, the "olm.gvk" property can be used to specify a Kubernetes group, version, and kind that this operator
version provides, and the "olm.gvk.required" property can be used to specify a GVK that this operator requires.
components that understand these properties can implement dependency resolution by matching GVK providers and
requirers.

See the [Properties](#properties) section for information about the properties understood by OLM.

Here is an example of an `olm.bundle` blob:
```yaml
schema: olm.bundle
package: foo
name: foo.v0.3.0

# image defined the location of the bundle image. (required)
image: quay.io/example-com/foo-bundle:v0.3.0
relatedImages:
 - # name is a descriptive name for this image that helps
   # identify its purpose in the context of the operator. (optional)
   name: bundle
   
   # image is the location of the image. (required)
   image: quay.io/example-com/foo-bundle:v0.3.0
   
 - name: operator
   image: quay.io/example-com/foo-operator:v0.3.0
 - name: foo-v1
   image: quay.io/example-com/foo:v1
 - name: foo-v2
   image: quay.io/example-com/foo:v2
properties:
- type: olm.package
  value:
    packageName: foo
    version: 0.3.0
- type: olm.package.required
  value:
    packageName: bar
    versionRange: ">=1.0.0 <2.0.0-0"
- type: olm.gvk
  value:
    group: example.com
    version: v1alpha1
    kind: Foo
- type: olm.gvk.required
  value:
    group: example.com
    version: v1
    kind: Bar
```

#### `olm.deprecations`

Operator authors can provide information for support and upgrades by using the optional `olm.deprecations` schema. 

The file-based catalog (FBC) deprecation schema consists of references to packages, bundles, and channels with a custom deprecation message.

A valid deprecation schema meets the following criteria:
- There must be only one schema per package
- The message must be a non-zero length
- The package must exist in the catalog
  
The deprecation feature does not consider overlapping deprecation (package vs channel vs bundle).

|              | `olm.package`                   | `olm.channel`        | `olm.bundle`          |
|--------------|---------------------------------|----------------------|-----------------------|
| Scope        | Entire Package                  | Single Channel       | Single Bundle Version |
| Requirements | `name` must be empty since it is inferred from the parent `package` field | `name`  is mandatory | `name`  is mandatory  |

The following example demonstrates each of the deprecation entry types:
```yaml
schema: olm.deprecations
package: deprecation-example
entries:
  - reference:
  	schema: olm.bundle
  	name: deprecation-example-operator.v1.68.0
    message: |
   	deprecation-example-operator.v1.68.0 is deprecated. Uninstall and install deprecation-example-operator.v1.72.0 for support.
  - reference:
  	schema: olm.package
    message: |
   	package deprecation-example is end of life.  Please use 'non-deprecated-example' package for support.
  - reference:
  	schema: olm.channel
  	name: alpha
    message: |
   	channel alpha is no longer supported.  Please switch to channel 'stable'.
```

### Properties

Properties are arbitrary pieces of metadata that can be attached to file-based catalog schemas. The type field is a
string that effectively specifies the semantic and syntactic meaning of the value field. The value can be any arbitrary
JSON/YAML.

OLM defines a handful of property types, again using the reserved `olm.*` prefix.

#### `olm.package`

An `olm.package` property defines the package name and version. This is a required property on bundles, and there must
be exactly one of these properties. The `packageName` must match the bundle's first-class `package` field, and the
`version` must be a valid [semantic version][semver]

The `olm.package` property [cue][cuelang-spec] schema is:
```cue
#PropertyPackage: {
  type: "olm.package"
  value: {
    packageName: string & !=""
    version: string & !=""
  }
}
```

#### `olm.gvk`

An `olm.gvk` property defines the group, version, and kind (GVK) of a Kubernetes API that is provided by this bundle.
This property is used by OLM to resolve a bundle with this property as a dependency for other bundles that list the same
GVK as a required API. The GVK must adhere to Kubernetes GVK validations.

The `olm.gvk` property [cue][cuelang-spec] schema is:
```cue
#PropertyGVK: {
  type: "olm.gvk"
  value: {
    group: string & !=""
    version: string & !=""
    kind: string & !=""
  }
}
```

#### `olm.package.required`

<!-- TODO: deprecate in favor of '#PropertyOLMConstraint: value: package' -->

An `olm.package.required` property defines the package name and version range of another package that this bundle
requires. For every required package property a bundle lists, OLM will ensure there is an operator installed on the
cluster for the listed package and in the required version range. The `versionRange` field must be a valid
[semver range][semver-range].

The `olm.package.required` property [cue][cuelang-spec] schema is:
```cue
#PropertyPackageRequired: {
  type: "olm.package.required"
  value: {
    packageName: string & !=""
    versionRange: string & !=""
  }
}
```

#### `olm.gvk.required`

<!-- TODO: deprecate in favor of '#PropertyOLMConstraint: value: gvk' -->

An `olm.gvk.required` property defines the group, version, and kind (GVK) of a Kubernetes API that this bundle requires.
For every required GVK property a bundle lists, OLM will ensure there is an operator installed on the cluster that
provides it. The GVK must adhere to Kubernetes GVK validations.

The `olm.gvk.required` property [cue][cuelang-spec] schema is:
```cue
#PropertyGVKRequired: {
  type: "olm.gvk.required"
  value: {
    group: string & !=""
    version: string & !=""
    kind: string & !=""
  }
}
```

#### `olm.csv.metadata`

`olm.csv.metadata` properties are used to include informational metadata about a bundle. This property is optional, and
there can be at most one of these properties per bundle. Bundles that include this property should not include any
`olm.bundle.object` properties. This property supersedes the `olm.bundle.object` property.

> **NOTE**: Core OLM does not require a `olm.csv.metadata` property to be included on bundles. However, the OLM Package
> Server (used by tooling such as the kubectl operator plugin and the OpenShift console) does require these properties
> to be able to serve metadata about the packages in a catalog. In order to satisfy the needs of the package server, catalog
> maintainers should use this property to include the CSV metadata for all bundles that are channel heads.

As of `opm` version 1.28.0, this property is automatically generated by when migrating SQLite catalogs with `opm migrate`
and when rendering SQLite catalogs and registry+v1 bundles with `opm render`. Catalogs containing `olm.csv.metadata`
properties must be served by `opm` binaries with version at least `1.28.0`.

#### `olm.constraint`

An [`olm.constraint` property][generic-constraint-ep] defines a dependency constraint of a particular type.
The `failureMessage` field is recommended but not required to be populated so readers know why a constraint
was specified, and errors can contain this string. The supported types are detailed in subsections.

The `olm.constraint` property [cue][cuelang-spec] schema is:

```cue
#ConstraintValue: {
  failureMessage?: string

  { gvk: #GVK } |
  { package: #Package } |
  { cel: #Cel } |
  { all: null | #CompoundConstraintValue } |
  { any: null | #CompoundConstraintValue } |
  { not: null | #CompoundConstraintValue }
}

#PropertyOLMConstraint: {
  type: "olm.constraint"
  value: #ConstraintValue
}
```

##### `#GVK`

`#GVK` is identical to the old top-level constraint `olm.gvk.required` value. The [cue][cuelang-spec] schema is:

```cue
#GVK: {
  group: string & !=""
  version: string & !=""
  kind: string & !=""
}
```

Example:

```cue
#PropertyOLMConstraint & {
  value: {
    failureMessage: "required for ..."
    gvk: #GVK & {
      group: "example.com"
      version: "v1"
      kind: "Foo"
    }
  }
}
```

##### `#Package`

`#Package` is identical to the old top-level constraint `olm.package.required` value. The [cue][cuelang-spec] schema is:

```cue
#Package: {
  packageName: string & !=""
  versionRange: string & !=""
}
```

Example:

```cue
#PropertyOLMConstraint & {
  value: {
    failureMessage: "required for ..."
    package: #Package & {
      packageName: "foo"
      versionRange: ">=1.0.0"
    }
  }
}
```

##### `#Cel`

The `cel` struct is specific to [Common Expression Language (CEL)](https://github.com/google/cel-go) constraint type that supports CEL as the expression language. The `cel` struct has `rule` field which contains the CEL expression string that will be evaluated against operator properties at the runtime to determine if the operator satisfies the constraint.

The `cel` constraint [cue][cuelang-spec] schema is:
```cue
#Cel: {
  rule: string & !=""
}
```

##### `#CompoundConstraintValue`

`#CompoundConstraintValue` is a [compound constraint][compound-constraint-ep] that represents either
a logical conjunction, disjunction, or negation of a constraint list, some of which are concrete
(ex. `#GVK` or `#Cel`), others being child compound constraints.
These logical operations correspond to `#ConstraintValue` fields `all`, `any`, or `not`, respectively.
The `not` compound constraint should only be used with an `#All` or `#Any` value,
since negating without first selecting a possible set of dependencies does not make sense.

The [cue][cuelang-spec] schema is:

```cue
#ConstraintList: [#ConstraintValue, ...#ConstraintValue]

#CompoundConstraintValue: {
  constraints: #ConstraintList
}
```

Example:

```cue
#PropertyOLMConstraint & {
  value: #ConstraintValue & {
    failureMessage: "Required for Baz because..."
    any: #CompoundConstraintValue & {
      constraints: #ConstraintList & [
        {
          failureMessage: "Pin kind Foo's version for stable versions"
          all: #CompoundConstraintValue & {
            constraints: #ConstraintList & [
              {
                package: #Package & {
                  packageName: "foo"
                  versionRange: ">=1.0.0"
                }
              },
              {
                gvk: #GVK & {
                  group: "foos.example.com"
                  version: "v1"
                  kind: "Foo"
                }
              }
            ]
          }
        },
        {
          failureMessage: "Pin kind Foo's version for pre-stable versions"
          all: #CompoundConstraintValue & {
            constraints: #ConstraintList & [
              {
                package: #Package & {
                  packageName: "foo"
                  versionRange: "<1.0.0"
                }
              },
              {
                gvk: #GVK & {
                  group: "foos.example.com"
                  version: "v1beta1"
                  kind: "Foo"
                }
              }
            ]
          }
        }
      ]
    }
  }
}
```

[generic-constraint-ep]: https://github.com/operator-framework/enhancements/blob/master/enhancements/generic-constraints.md
[compound-constraint-ep]: https://github.com/operator-framework/enhancements/blob/master/enhancements/compound-bundle-constraints.md

#### `olm.bundle.object` (deprecated)

`olm.bundle.object` properties are used to inline a bundle's manifests directly in the catalog.

> **NOTE**: Core OLM does not require `olm.bundle.object` properties to be included on bundles. However, the OLM Package
> Server (used by tooling such as the kubectl operator plugin and the OpenShift console) does require these properties
> to be able to serve metadata about the packages in a catalog. In order to satisfy the needs of the package server, catalog
> maintainers should use this property to include the CSV for all bundles that are channel heads.
>
> This property is _deprecated_ because it causes major performance issues when loading and serving file-based catalogs.
> The `olm.csv.metadata` property, which serves the exact same purpose, should be used instead.

A bundle object property can contain inlined data using the `value.data` field, which must be the base64-encoded string
of that manifest.

The `olm.bundle.object` property [cue][cuelang-spec] schema is:
```cue

#PropertyBundleObject: {
  type: "olm.bundle.object"
  value: #propertyBundleObjectData
}

#propertyBundleObjectData: {
    data: string & !=""
}
```

[cuelang-spec]: https://cuelang.org/docs/references/spec/
[semver]: https://semver.org/spec/v2.0.0.html
[semver-range]: https://github.com/blang/semver/blob/master/README.md#ranges

## CLI

<!--
TODO(joelanford): We should auto-generate this from cobra CLI doc tooling.
-->

### `opm init`

```
Generate an olm.package declarative config blob

Usage:
  opm init <packageName> [flags]

Flags:
  -c, --default-channel string   The channel that subscriptions will default to if unspecified
  -d, --description string       Path to the operator's README.md (or other documentation)
  -h, --help                     help for init
  -i, --icon string              Path to package's icon
  -o, --output string            Output format (json|yaml) (default "json")

Global Flags:
      --skip-tls   skip TLS certificate verification for container image registries while pulling bundles or index
```

### `opm render`

```
Generate a declarative config blob from the provided index images, bundle images, and sqlite database files

Usage:
  opm render [index-image | bundle-image | sqlite-file]... [flags]

Flags:
  -h, --help            help for render
  -o, --output string   Output format (json|yaml) (default "json")

Global Flags:
      --skip-tls   skip TLS certificate verification for container image registries while pulling bundles or index
```

### `opm validate`

```
Validate the declarative config JSON file(s) in a given directory

Usage:
  opm validate <directory> [flags]

Flags:
  -h, --help   help for validate

Global Flags:
      --skip-tls   skip TLS certificate verification for container image registries while pulling bundles or index
```

### `opm serve`

```
This command serves declarative configs via a GRPC server.

NOTE: The declarative config directory is loaded by the serve command at
startup. Changes made to the declarative config after the this command starts
will not be reflected in the served content.

Usage:
  opm serve <source_path> [flags]

Flags:
      --debug                    enable debug logging
  -h, --help                     help for serve
  -p, --port string              port number to serve on (default "50051")
  -t, --termination-log string   path to a container termination log file (default "/dev/termination-log")

Global Flags:
      --skip-tls   skip TLS certificate verification for container image registries while pulling bundles or index
```

### `opm alpha diff`

```
Diff a set of old and new catalog references ("refs") to produce a declarative config containing only packages channels, and versions not present in the old set, and versions that differ between the old and new sets. This is known as "latest" mode. These references are passed through 'opm render' to produce a single declarative config.

 This command has special behavior when old-refs are omitted, called "heads-only" mode: instead of the output being that of 'opm render refs...' (which would be the case given the preceding behavior description), only the channel heads of all channels in all packages are included in the output, and dependencies. Dependencies are assumed to be provided by either an old ref, in which case they are not included in the diff, or a new ref, in which case they are included. Dependencies provided by some catalog unknown to 'opm alpha diff' will not cause the command to error, but an error will occur if that catalog is not serving these dependencies at runtime.

Usage:
  opm alpha diff [old-refs]... new-refs... [flags]

Examples:
  # Diff a catalog at some old state and latest state into a declarative config index.
  mkdir -p catalog-index
  opm alpha diff registry.org/my-catalog:abc123 registry.org/my-catalog:def456 -o yaml > ./my-catalog-index/index.yaml

  # Build and push this index into an index image.
  opm generate dockerfile ./my-catalog-index
  docker build -t registry.org/my-catalog:latest-abc123-def456 -f index.Dockerfile .
  docker push registry.org/my-catalog:latest-abc123-def456

  # Create a new catalog from the heads of an existing catalog, then build and push the image like above.
  opm alpha diff registry.org/my-catalog:def456 -o yaml > my-catalog-index/index.yaml
  docker build -t registry.org/my-catalog:headsonly-def456 -f index.Dockerfile .
  docker push registry.org/my-catalog:headsonly-def456

Flags:
      --ca-file string   the root Certificates to use with this command
      --debug            enable debug logging
  -h, --help             help for diff
  -o, --output string    Output format (json|yaml) (default "yaml")

Global Flags:
      --skip-tls   skip TLS certificate verification for container image registries while pulling bundles or index
```

### `opm generate dockerfile`

```
Generate a Dockerfile for a declarative config index.

This command creates a Dockerfile in the same directory as the <dcRootDir>
(named <dcDirName>.Dockerfile) that can be used to build the index. If a
Dockerfile with the same name already exists, this command will fail.

When specifying extra labels, note that if duplicate keys exist, only the last
value of each duplicate key will be added to the generated Dockerfile.

Usage:
  opm generate dockerfile <dcRootDir> [flags]

Flags:
  -i, --binary-image string    Image in which to build catalog. (default "quay.io/operator-framework/upstream-opm-builder")
  -l, --extra-labels strings   Extra labels to include in the generated Dockerfile. Labels should be of the form 'key=value'.
  -h, --help                   help for dockerfile

Global Flags:
      --skip-tls   skip TLS certificate verification for container image registries while pulling bundles or index
```

## Guidelines

### Immutable bundles

OLM's general advice is that bundle images and their metadata should be treated as immutable. If a broken bundle has
been pushed to an index, you must assume that at least one of your users has upgraded to that bundle. Based on that
assumption, you must release another bundle with an upgrade edge from the broken bundle to ensure users with the broken
bundle installed receive an upgrade. OLM will not reinstall an installed bundle if the contents of that bundle are
updated in the index.

However, there are some cases where a change in the index metadata is preferred. For example:
- Channel promotion - if you already released a bundle and later decide that you'd like to add it to another channel,
  simply add an entry for your bundle in another `olm.channel` blob.
- New upgrade edges - if you release a new 1.2.z (e.g. 1.2.4), but 1.3.0 is already released, you can update the index
  metadata for 1.3.0 to skip 1.2.4.

### Use of source control

OLM highly recommends storing index metadata in source control and treating the source-controlled metadata as the source
of truth. Updates to index images should:
- Update the source-controlled index directory with a new commit.
- Build and push the index image. OLM suggests using a consistent tagging taxonomy (e.g. `:latest` or
   `:<targetClusterVersion>` so that users can receive updates to an index as they become available.

<!--
TODO(joelanford): Add a link to an file-based catalog repository when one exists in the future.
-->

## Examples

### Building a composite catalog

With file-based catalogs, catalog maintainers can focus on operator curation and compatibility.
Since operator authors have already produced operator-specific catalogs for their operators, catalog
maintainers can build their catalog simply by rendering each operator catalog into a subdirectory of the
catalog's root catalog directory.

There are many possible ways to build a catalog, but an extremely simple approach would be to:

- Maintain a single configuration file containing image references for each operator in the catalog
   ```yaml
   name: community-operators
   repo: quay.io/community-operators/catalog
   tag: latest
   references:
   - name: etcd-operator
     image: quay.io/etcd-operator/catalog@sha256:5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03
   - name: prometheus-operator
     image: quay.io/prometheus-operator/catalog@sha256:e258d248fda94c63753607f7c4494ee0fcbe92f1a76bfdac795c9d84101eb317
   ```

- Run a simple script that parses this file and creates a new catalog from its references
   ```bash
   name=$(yq eval '.name' catalog.yaml)
   mkdir "$name"
   yq eval '.name + "/" + .references[].name' catalog.yaml | xargs mkdir
   for l in $(yq e '.name as $catalog | .references[] | .image + "|" + $catalog + "/" + .name + "/index.yaml"' catalog.yaml); do
     image=$(echo $l | cut -d'|' -f1)
     file=$(echo $l | cut -d'|' -f2)
     opm render "$image" > "$file"
   done
   opm generate dockerfile "$name"
   indexImage=$(yq eval '.repo + ":" + .tag' catalog.yaml)
   docker build -t "$indexImage" -f "$name.Dockerfile" .
   docker push "$indexImage"
   ```
>Note: The `yq` binary used in the script can be found [here](https://github.com/mikefarah/yq)

## Automation

Operator authors and catalog maintainers are encouraged to automate their catalog maintenance with CI/CD workflows.
catalog maintainers could further improve on this by building Git-ops automation that:
- Checks that PR authors are permitted to make the requested changes (e.g. updating their package's image reference)
- Checks that the catalog updates pass `opm validate`
- Checks that the updated bundle and/or catalog image reference(s) exist, the catalog images run successfully in a cluster,
  and operators from that package can be successfully installed.
- Automatically merges PRs that pass these checks.
- Automatically rebuilds and republishes the catalog image.

An example catalog that automates a lot of these workflows can be found at https://github.com/operator-framework/cool-catalog
