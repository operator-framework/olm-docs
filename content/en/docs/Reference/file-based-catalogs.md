---
title: "File-based Catalogs"
linkTitle: "File-based Catalogs"
weight: 4
date: 2021-07-29
---

File-based catalogs are the latest iteration of OLM's index format. It is a fully plaintext-based (JSON or YAML)
evolution of the previous sqlite database format that is fully backwards compatible.

## Design
The primary design goal for this format is to enable index editing, composability, and extensibility. 

### Editing

With file-based catalogs, users interacting with the contents of an index are able to make direct changes to the index
format and verify that their changes are valid. 

Because this format is plaintext JSON or YAML, index maintainers can easily manipulate index metadata by hand or with
widely known and supported JSON or YAML tooling (e.g. `jq`).

This editability enables features and user-defined extensions, such as:
- Promoting an existing bundle to a new channel
- Changing the default channel of a package
- Custom algorithms for adding, updating, adding removing upgrade edges.

### Composability

File-based catalogs are stored in an arbitrary directory hierarchy, which enables index composition. If I have two
separate file-based catalog directories, `indexA` and `indexB`, I can make a new combined index by making a new
directory `indexC` and copying `indexA` and `indexB` into it.

This composability enables decentralized indexes. The format permits operator authors to maintain operator-specific
indexes and index maintainers to trivially build an index composed of individual operator indexes.

> NOTE: Duplicate packages and duplicate bundles within a package are not permitted. The `opm validate` command will
> return an error if any duplicates are found.

Since operator authors are most familiar with their operator, its dependencies, and its upgrade compatibility, they are
able to maintain their own operator-specific index and have direct control over its contents. With file-based catalogs,
operator authors own the task of building and maintaining their packages in an index. Composite index maintainers treat
packages as a black box; they own the task of curating the packages in their catalog and publishing the catalog to
users. 

File-based catalogs can be composed by combining multiple other catalogs or by extracting subsets of one catalog, or a
combination of both of these.

### Extensibility

The final design goal is to provide extensibility around indexes. The file-based catalog spec is a low-level
representation of an index. While it can be maintained directly in its low-level form, we expect many index maintainers
to build interesting extensions on top that can be used by their own custom tooling to make all sorts of mutations. For
example, one could imagine a tool that translates a high-level API like (mode=semver) down to the low-level file-based
catalog format for upgrade edges. Or perhaps an index maintainer needs to customize all of the bundle metadata by adding
a new property to bundles that meet a certain criteria.

The OLM developer community will be making use of this extensibility to build more official tooling on top of the
low-level APIs, but the major benefit is that index maintainers have this capability as well.

## Specification

### Structure

File-based catalogs can be stored and loaded from directory-based filesystems.

`opm` loads the catalog by walking the root directory and recursing into subdirectories. It attempts to load every file
it finds and fails if any errors occur.

Non-catalog files can be ignored using `.indexignore` files, which behave identically to `.gitignore` files. That is,
they have the same rules for [patterns](https://git-scm.com/docs/gitignore#_pattern_format) and precedence.

> #### Example `.gitignore` file
> ```gitignore
> # Ignore everything except non-object .json and .yaml files
> **/*
> !*.json
> !*.yaml
> **/objects/*.json
> **/objects/*.yaml
> ```


Index maintainers have flexibility to chose their desired layout, but the OLM team recommends storing each package's
file-based catalog blobs in separate sub-directories. Each individual file can be either JSON or YAML -- it is not
necessary for every file in an index to use the same format. 

This layout has the property that each sub-directoriy in the directory hierarchy is a self-contained index, which makes
index composition, discovery, and navigation as simple as trivial filesystem operations.

> #### Basic recommended structure
> ```
> index
> ├── pkgA
> │   └── index.yaml
> ├── pkgB
> │   ├── .indexignore
> │   ├── index.yaml
> │   └── objects
> │       └── pkgB.v0.1.0.clusterserviceversion.yaml
> └── pkgC
>     └── index.json
> ```

This `index` could also be trivially included in a parent index by simply copying it into the parent index's root
directory.

### Schema

At its core, file-based catalogs use a simple format that can be extended with arbitrary schemas. The format that all
file-based catalog blobs must adhere to is the `Meta` schema. The below [cue][cuelang-spec] `_Meta` schema defines all
file-based catalog blobs.

> **NOTE**: No cue schemas listed in this specification should be considered exhaustive. The `opm validate` command has
> additional validations that are difficult/impossible to express concisely in cue.

```cue
_Meta: {
  // schema is required and must be a non-empty string
  schema: string & !=""

  // package is optional, but if it's defined, it must be a non-empty string
  package?: string & !=""

  // properties is optional, but if it's defined, it must be a list of 0 or more properties
  properties?: [... #Property]
}

#Property: {
  // type is required
  type: string & !=""

  // value is required, and it must not be null
  value: !=null
}
```

### OLM-defined schemas

An OLM index currently uses two schemas: `olm.package` and `olm.bundle`, which correspond to OLM's existing package and
bundle concepts.

Each operator package in an index requires exactly one `olm.package` blob and one or more `olm.bundle` blobs.

> **NOTE**: All `olm.*` schemas are reserved for OLM-defined schemas. Custom schemas must use a unique prefix (e.g. a
> domain that you own).

#### `olm.package`

An `olm.package` defines package-level metadata for an operator. This includes its name, description, default channel
and icon.

The `olm.package` [cue][cuelang-spec] schema is:
```cue
#Package: {
  schema: "olm.package"
  
  // Package name
  name: string & !=""

  // A description of the package
  description?: string

  // The package's default channel
  defaultChannel: string & !=""
  
  // An optional icon
  icon?: {
    base64data: string
    mediatype:  string
  }
}
```

#### `olm.bundle`

<!--
TODO(joelanford): Add a description of the `olm.bundle` schema here 
-->

The `olm.bundle` cue schema is:
```cue
#Bundle: {
  schema: "olm.bundle"
  package: string & !=""
  name: string & !=""
  image: string & !=""
  properties: [...#Property]
  relatedImages?: [...#RelatedImage]
}

#Property: {
  // type is required
  type: string & !=""

  // value is required, and it must not be null
  value: !=null
}

#RelatedImage: {
  // image is the image reference
  image: string & !=""
  
  // name is an optional descriptive name for an image that
  // helps identify its purpose in the context of the bundle
  name?: string & !=""
}
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

#### `olm.channel`

An `olm.channel` property defines a channel that a bundle is in, and optionally, the name of another bundle that it
replaces in that channel.

A bundle can include multiple `olm.channel` properties, but it is invalid to define multiple `olm.channel` properties
for the same channel name.

Lastly, it is valid for an `olm.channel`'s replaces value to reference another bundle that cannot be found in this index
(or even another index) as long as other channel invariants still hold (e.g. a channel cannot have multiple heads).

The `olm.channel` property [cue][cuelang-spec] schema is:
```cue
#PropertyChannel: {
  type: "olm.channel"
  value: {
    name: string & !=""
    replaces?: string & !=""
  }
}
```

#### `olm.skips`

An `olm.skips` property defines another bundle that this bundle skips. This property applies to all channels.

Any number of skips properties can be set on a bundle.

The `olm.skips` property [cue][cuelang-spec] schema is:
```cue
#PropertySkips: {
  type: "olm.skips"
  value: string & !=""
}
```

#### `olm.skipRange`

An `olm.skipRange` property defines a [range of semver versions][semver-range] of other bundles that this bundle skips.
This property applies to all channels.

It is invalid to include multiple `olm.skipRange` properties on a bundle.

The `olm.skipRange` property [cue][cuelang-spec] schema is:
```cue
#PropertySkipRange: {
  type: "olm.skipRange"
  value: string & !=""
}
```

#### `olm.package.required`

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

#### `olm.bundle.object` (alpha)

`olm.bundle.object` properties are used to inline (or reference) a bundle's manifests directly in the index.

> **NOTE**: Core OLM does not require `olm.bundle.object` properties to be included on bundles. However, the OLM Package
> Server (used by tooling such as the kubectl operator plugin and the OpenShift console) does require these properties
> to be able to serve metadata about the packages in an index.
> 
> This property is in _alpha_ because it will likely be rendered obsolete when updates can be made to the OLM Package
> Server to no longer require manifests in the index.

A bundle object property can contain inlined data using the `value.data` field, which must the base64-encoded string of
that manifest.

Alternately, a bundle object property can be a reference to a file relative to the location of file in which the bundle
is declared. Any referenced files must be within the catalog root.

The `olm.bundle.object` property [cue][cuelang-spec] schema is:
```cue

#PropertyBundleObject: {
  type: "olm.bundle.object"
  value: #propertyBundleObjectRef | #propertyBundleObjectData
} 

#propertyBundleObjectRef: {
    ref: string & !=""
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
  opm alpha generate dockerfile ./my-catalog-index
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

### `opm alpha generate dockerfile`

```
Generate a Dockerfile for a declarative config index.

This command creates a Dockerfile in the same directory as the <dcRootDir>
(named <dcDirName>.Dockerfile) that can be used to build the index. If a
Dockerfile with the same name already exists, this command will fail.

When specifying extra labels, note that if duplicate keys exist, only the last
value of each duplicate key will be added to the generated Dockerfile.

Usage:
  opm alpha generate dockerfile <dcRootDir> [flags]

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
  simply add an `olm.channel` property to the `olm.bundle`
- New upgrade edges - if you release a new 1.2.z (e.g. 1.2.4), but 1.3.0 is already released, you can update the index
  metadata for 1.3.0 to skip 1.2.4.
  
### Use of source control

OLM highly recommends storing index metadata in source control and treating the source-controlled metadata as the source
of truth. Updates to index images should:
1. Update the source-controlled index directory with a new commit.
2. Build and push the index image. OLM suggests using a consistent tagging taxonomy (e.g. `:latest` or 
   `:<targetClusterVersion>` so that users can receive updates to an index as they become available.

## Example: Building a composite catalog

With file-based catalogs, catalog maintainers can focus on operator curation and compatibility.
Since operator authors have already produced operator-specific indexes for their operators, catalog
maintainers can build their catalog simply by rendering each operator index into a subdirectory of the
catalog's root index directory.

There are many possible ways to build a catalog, but an extremely simple approach would be to:

1. Maintain a single configuration file containing image references for each operator in the catalog
   ```yaml
   name: community-operators
   repo: quay.io/community-operators/catalog
   tag: latest
   references:
   - name: etcd-operator
     image: quay.io/etcd-operator/index@sha256:5891b5b522d5df086d0ff0b110fbd9d21bb4fc7163af34d08286a2e846f6be03
   - name: prometheus-operator
     image: quay.io/prometheus-operator/index@sha256:e258d248fda94c63753607f7c4494ee0fcbe92f1a76bfdac795c9d84101eb317
   ```

2. Run a simple script that parses this file and creates a new catalog from its references
   ```bash
   name=$(yq eval '.name' catalog.yaml)
   mkdir "$name" 
   yq eval '.name + "/" + .references[].name' catalog.yaml | xargs mkdir
   for l in $(yq e '.name as $catalog | .references[] | .image + "|" + $catalog + "/" + .name + "/index.yaml"' catalog.yaml); do
     image=$(echo $l | cut -d'|' -f1)
     file=$(echo $l | cut -d'|' -f2)
     opm render "$image" > "$file"
   done
   opm alpha generate dockerfile "$name"
   indexImage=$(yq eval '.repo + ":" + .tag' catalog.yaml)
   docker build -t "$indexImage" -f "$name.Dockerfile" .
   docker push "$indexImage"
   ```

## Automation

Operator authors and catalog maintainers are encouraged to automate their index maintenance with CI/CD workflows.
Catalog maintainers could further improve on this by building Git-ops automation that:
1. Checks that PR authors are permitted to make the requested changes (e.g. updating their package's image reference)
2. Checks that the index updates pass `opm validate`
3. Checks that the updated bundle and/or index image reference(s) exist, the index images run successfully in a cluster,
   and operators from that package can be successfully installed.
4. Automatically merges PRs that pass these checks.
5. Automatically rebuilds and republishes the index image.
