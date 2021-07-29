---
title: "Declarative Config"
linkTitle: "Declarative Config"
weight: 4
date: 2021-07-29
---

Declarative Config (DC) is the latest iteration of OLM's index format. It is a fully plaintext-based (JSON or YAML) evolution of the previous sqlite database format that is fully backwards compatible.

## Motivation
The primary motivations for this new format are to enable index editting, composability, and extensibility. 

### Editting

With DC, users interacting with the contents of an index are able to make direct changes to the index format and verify that their changes are valid. 

Because the index is now stored in plaintext rather than an sqlite database, index maintainers can update an index without the use of a custom index-aware tool, like `opm`.

This editability opens the door for new features and extensions that were otherwise difficult to implement and maintain in a single tool. For example:
- Promoting an existing bundle to a new channel
- Changing the default channel of a package
- Adding, updating, or removing upgrade edges

### Composability

Declarative Configs are stored in an arbitrary directory hierarchy, which enables index composition. If I have two separate DC directories, `indexA` and `indexB`, I can make a new combined index by making a new directory `indexC` and copying `indexA` and `indexB` into it.

This composability enables decentralized indexes. The format permits operator authors to maintain operator-specific indexes and index maintainers to trivially build an index composed of individual operator indexes.

One of the major benefits is that those who are most familiar with an operator, its dependencies, and its upgrade compatibility (i.e. the operator authors) are able to maintain their own operator-specific index and have direct control over its contents. DC moves the task of building and maintaining indexes more towards operator authors, thus giving composite index maintainers more time to build value around their compositions.

Another benefit is that the format enables composite index maintainers to build their index without the knowledge or coordination of the maintainers of the sub-indexes. Indexes like this can be composed by combining multiple other indexes or by extracting only necessary subsets of one index, or a combination of both of these.

### Extensibility

Another motivation is to enable more extensibility around indexes. DC is a low-level representation of an index. While it can be maintained directly in its low-level form, we expect many index maintainers to build interesting extensions on top that can be used by their own custom tooling to make all sorts of mutations. For example, one could imagine a tool that translates a high-level API like (mode=semver) down to the low-level DC format for upgrade edges. Or perhaps an index maintainer needs to customize all of the bundle metadata by adding a new property to bundles that meet a certain criteria.

The OLM developer community will be making use of this extensibility to build more official tooling on top of the low-level APIs, but the major benefit is that index maintainers have this capability as well.

## Specification

### Structure

Declarative config can be stored and loaded from directory-based filesystems.

`opm` loads declarative config by walking the root directory and recursing into subdirectories. It attempts to load every file it finds as declarative config and fails if any errors occur.

Non-DC files can be ignored using `.indexignore` files, which behave identically to `.gitignore` files. That is, they have the same rules for [patterns](https://git-scm.com/docs/gitignore#_pattern_format) and precedence.

> #### Example `.gitignore` file
> ```gitignore
> # Ignore everything except non-object .json and .yaml files
> **/*
> !*.json
> !*.yaml
> **/objects/*.json
> **/objects/*.yaml
> ```


Index maintainers have flexibility to chose their desired layout, but the OLM team recommends storing each package's DC blobs in separate sub-directories. Each individual DC file can be either JSON or YAML -- it is not necessary for every file in an index to use the same format. 

This layout has the property that each sub-directoriy in the directory hierarchy is a self-contained index, which makes index composition, discovery, and navigation as simple as trivial filesystem operations.

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

This `index` could also be trivially included in a parent index by somply copying it into the parent index's root directory.

### Schema

At its core, declarative config is a simple format that can be extended with arbitrary schemas. The format that all DC blobs must adhere to is the `Meta` schema. The below [cue][cuelang-spec] `_Meta` schema defines all DC blobs.

> **NOTE**: No cue schemas listed in this specification should be considered exhaustive. The `opm validate` command has additional validations that are difficult/impossible to express concisely in cue.

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

An OLM index currently uses two schemas: `olm.package` and `olm.bundle`, which correspond to OLM's existing package and bundle concepts.

Each operator package in an index requires exactly one `olm.package` blob and one or more `olm.bundle` blobs.

> **NOTE**: All `olm.*` schemas are reserved for OLM-defined schemas. Custom schemas must use a unique prefix (e.g. a domain that you own).

#### `olm.package`

An `olm.package` defines package-level metadata for an operator. This includes its name, description, default channel and icon.

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

Properties are arbitrary pieces of metadata that can be attached to DC schemas. The type field is a string that effectively specifies the semantic and syntactic meaning of the value field. The value can be any arbitrary JSON/YAML.


OLM defines a handful of property types, again using the reserved `olm.*` prefix.

#### `olm.package`

An `olm.package` property defines the package name and version. This is a required property on bundles, and there must be exactly one of these properties. The `packageName` must match the bundle's first-class `package` field, and the `version` must be a valid [semantic version][semver]

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

An `olm.gvk` property defines the group, version, and kind (GVK) of a Kubernetes API that is provided by this bundle. This property is used by OLM to resolve a bundle with this property as a dependency for other bundles that list the same GVK as a required API. The GVK must adhere to Kubernetes GVK validations.

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

An `olm.channel` property defines a channel that a bundle is in, and optionally, the name of another bundle that it replaces in that channel.

A bundle can include multiple `olm.channel` properties, but it is invalid to define multiple `olm.channel` properties for the same channel name.

Lastly, it is valid for an `olm.channel`'s replaces value to reference another bundle that cannot be found in this index (or even another index) as long as other channel invariants still hold (e.g. a channel cannot have multiple heads).

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

An `olm.skipRange` property defines a [range of semver versions][semver-range] of other bundles that this bundle skips. This property applies to all channels.

It is invalid to include multiple `olm.skipRange` properties on a bundle.

The `olm.skipRange` property [cue][cuelang-spec] schema is:
```cue
#PropertySkipRange: {
  type: "olm.skipRange"
  value: string & !=""
}
```

#### `olm.package.required`

An `olm.package.required` property defines the package name and version range of another package that this bundle requires. For every required package property a bundle lists, OLM will ensure there is an operator installed on the cluster for the listed package and in the required version range. The `versionRange` field must be a valid [semver range][semver-range].

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

An `olm.gvk.required` property defines the group, version, and kind (GVK) of a Kubernetes API that this bundle requires. For every required GVK property a bundle lists, OLM will ensure there is an operator installed on the cluster that provides it. The GVK must adhere to Kubernetes GVK validations.

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

> **NOTE**: Core OLM does not require `olm.bundle.object` properties to be included on bundles. However, the OLM Package Server (used by tooling such as the kubectl operator plugin and the OpenShift console) does require these properties to be able to serve metadata about the packages in an index.
> 
> This property is in _alpha_ because it will likely be rendered obsolete when updates can be made to the OLM Package Server to no longer require manifests in the index.

A bundle object property can contain inlined data using the `value.data` field, which must the base64-encoded string of that manifest

Alternately, a bundle object property can be a reference to a file relative to the location of file in which the bundle is declared. Any referenced files must be within the declarative config root.

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

### `opm init`
### `opm render`
### `opm validate`
### `opm serve`
### `opm alpha diff`
### `opm alpha generate dockerfile`

## Workflows

### Operator authors & package maintainers
### Index maintainers
### Cluster administrators

