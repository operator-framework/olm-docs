---
title: "Upgrade Graph Visualization"
linkTitle: "Upgrade Graph Visualization (alpha)"
weight: 5
date: 2024-11-18
---

>Note: `upgrade graph visualization` is **ALPHA** functionality and may adopt breaking changes


## Concept

File-Based Catalogs (FBC) are a major improvement to the imperative update graph approaches of previous versions. FBCs give operator authors a [declarative and deterministic approach to defining their update graph](https://olm.operatorframework.io/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/). However, FBCs can get complex, especially as the number of releases and dependencies scale. The upgrade graphs, in particular, for an operator can be difficult to reason about abstractly. Having an easy way to understand and quickly troubleshoot issues such as orphaned or stranded versions where there is no upgrade path forward from the orphaned or stranded version. To support understanding the upgrade graphs of operators in an index, we introduce a tool to generate a mermaid-formatted visualization through the `render-graph` command.

## Visualizing Upgrade Graphs

The `render-graph` command generates the upgrade graphs of operators for a given index in mermaid-format. The resulting output can then be viewed in online services such as [mermaid.live](https://mermaid.live) or converted to an image using a tool such as [mermaid-cli](https://github.com/mermaid-js/mermaid-cli).

### Usage

```sh
opm alpha render-graph [index-image | fbc-dir] [flags]
```

| Flag                      | Description                                                                               |
| ------------------------- | ----------------------------------------------------------------------------------------- |
| --draw-v0-semantics bool | whether to indicate OLMv0 semantics in the output; default is to simply represent the upgrade graph |
| -h, --help                | prints help/usage information                                                             |
| --minimum-edge string     | the channel edge to use as the lower bound of the set of edges composing the upgrade graph; default is to include all edges |
| -p, --package-name string | a specific package name to filter output; default is to include all packages in reference |
| --skip-tls-verify         | skip TLS certificate verification for container image registries while pulling bundles    |
| --use-http                | use plain HTTP for container image registries while pulling bundles                       |

`--skip-tls-verify` and `--use-http` are mutually exclusive flags.

### Examples 
For the following examples, we define a catalog with the following FBC directory structure:
```
example_catalog/
└── testoperator
    └── index.yaml
```

The index.yaml file contains the following:
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
- name: testoperator.v0.2.3
  skips:
  - testoperator.v0.2.2
- name: testoperator.v0.3.0
  replaces: testoperator.v0.2.2
name: candidate-v0
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
- name: testoperator.v0.2.2
name: stable-v0
package: testoperator
schema: olm.channel
```

#### Generating a channel graph
To generate the upgrade graphs of each channel, run the following:

`opm alpha render-graph example_catalog/`

This will output a mermaid graph that looks like this when rendered into an image:

![Full Upgrade Graph](/docs/Reference/images/full-upgrade-graph.png)

#### Generating a scaled vector graphic (SVG)
To generate a scaled vector graphic (SVG) directly from the output results of the `render-graph` command, use the following:

```
opm alpha render-graph example_catalog | \
    docker run --rm -i -v "$PWD":/data ghcr.io/mermaid-js/mermaid-cli/mermaid-cli -o /data/example_catalog.svg
```

#### Generating a channel graph for a single operator in a catalog
Say we now have multiple operators in our example_catalog:
```
example_catalog/
└── testoperator
    └── index.yaml
└── anotheroperator
    └── index.yaml
└── yetanotheroperator
    └── index.yaml
```
Running the `render-graph` command on the `example_catalog/` directory would now generate upgrade graphs for all of these operators. To limit the generated graph to only the testoperator, we would use the following:
`opm alpha render-graph -p testoperator example_catalog/`

### Advanced Examples
The following examples expand on advanced topics related to upgrade graphs that can be understood more easily via visualizations generated by the `render-graph` command.

#### Visualizing skipRanges
Consistently using skipRanges allows for a given version to be upgraded to any other newer versions. A real-world example of this can be seen in the security-profiles-operator upgrade graph:

![Security Profiles Operator Full Upgrade Graph](/docs/Reference/images/spo-full-graph.png)

#### Limiting the upgrade graph to a particular version context
Say we are only interested in the upgrade graph after version v0.8.0. We can limit the upgrade graph to the v0.8.0+ context using the following:
`opm alpha render-graph -p security-profiles-operator --minimum-edge security-profiles-operator.v0.8.0 quay.io/operatorhubio/catalog:latest`

![Security Profiles Operator Limited Upgrade Graph](/docs/Reference/images/spo-limited-graph.png)

#### Visualizing orphaned or stranded versions

Orphaned or stranded versions are operator versions that do not have an upgrade path to newer versions. This is a critical issue for operator authors to detect and fix, as users on orphaned versions cannot upgrade to newer releases.

##### What are orphaned/stranded versions?

A version is considered orphaned or stranded when:
1. It is not the channel head (latest version)
2. AND it has no upgrade path (via `replaces`, `skips`, or `skipRange`) to any newer version

##### How orphaned versions occur

Orphaned versions can occur in several ways:

1. **Missing upgrade edges**: Forgetting to provide a `replaces`, `skips`, or `skipRange` for a version
2. **Graph truncation**: When using `--minimum-edge` to filter the upgrade graph, versions below the minimum edge that are in channels not containing the minimum edge become orphaned
3. **Channel misalignment**: A channel that ends at an older version while other channels continue to newer versions

##### Why orphaned versions are problematic

When users are installed on an orphaned version:
- They cannot upgrade to newer operator versions through normal OLM upgrade mechanisms
- They may miss critical bug fixes and security patches
- They may be stuck on that version even during cluster upgrades
- Manual intervention is required to migrate to a non-orphaned version
- This creates operational burden and potential downtime

##### Example: Orphaned versions due to graph truncation

Consider an operator with two channels: `stable` and `candidate`. The `stable` channel has the full upgrade path from v1.0.0 to v3.0.0, while the `candidate` channel only goes up to v2.1.0 for testing purposes.

**FBC Configuration:**
```yaml
---
defaultChannel: stable
name: myoperator
schema: olm.package
---
# Bundle definitions (abbreviated for clarity)
# myoperator.v1.0.0 through myoperator.v3.0.0
---
entries:
- name: myoperator.v1.0.0
- name: myoperator.v1.1.0
  replaces: myoperator.v1.0.0
- name: myoperator.v1.2.0
  replaces: myoperator.v1.1.0
- name: myoperator.v2.0.0
  replaces: myoperator.v1.2.0
- name: myoperator.v2.1.0
  replaces: myoperator.v2.0.0
- name: myoperator.v2.2.0
  replaces: myoperator.v2.1.0
- name: myoperator.v3.0.0
  replaces: myoperator.v2.2.0
name: stable
package: myoperator
schema: olm.channel
---
entries:
- name: myoperator.v1.0.0
- name: myoperator.v1.1.0
  replaces: myoperator.v1.0.0
- name: myoperator.v1.2.0
  replaces: myoperator.v1.1.0
- name: myoperator.v2.0.0
  replaces: myoperator.v1.2.0
- name: myoperator.v2.1.0
  replaces: myoperator.v2.0.0
  # Note: candidate channel stops at v2.1.0
name: candidate
package: myoperator
schema: olm.channel
```

**Full upgrade graph (no truncation):**

```sh
opm alpha render-graph example_catalog/
```

The full graph shows both channels with their complete upgrade paths:

![Orphaned Example Full Graph](/docs/Reference/images/orphaned-full-graph.png)

**Truncated upgrade graph showing orphaned versions:**

Now suppose we want to restrict installations to v2.2.0 and newer (for example, to enforce a minimum supported version). We can use `--minimum-edge` to visualize what happens:

```sh
opm alpha render-graph --minimum-edge myoperator.v2.2.0 example_catalog/
```

![Orphaned Example Truncated Graph](/docs/Reference/images/orphaned-truncated-graph.png)

**Critical observation**: After truncation at v2.2.0, the entire `candidate` channel disappears from the graph because its channel head (v2.1.0) is below the minimum edge. This means:

- **All users on the `candidate` channel are orphaned** - they have no upgrade path
- Users on `candidate` v2.1.0 cannot upgrade to v2.2.0 or v3.0.0 in the `stable` channel
- Users would be stuck on v2.1.0 indefinitely
- The catalog effectively becomes unusable for anyone subscribed to the `candidate` channel

##### Detecting orphaned versions

Use the `render-graph` command to visualize your upgrade graph and identify orphaned versions:

1. **Generate the full graph** to understand your complete upgrade topology
2. **Test with different `--minimum-edge` values** to simulate version restrictions
3. **Look for disconnected nodes** - versions with no outgoing edges and no incoming edges from newer versions
4. **Check all channels** - ensure each channel either:
   - Has a clear upgrade path to the latest version, OR
   - Is intentionally terminated with documentation explaining the migration path

##### Fixing orphaned versions

When you identify orphaned versions, you have several options:

1. **Add upgrade edges**: Add `replaces`, `skips`, or `skipRange` to connect orphaned versions to the upgrade graph
2. **Remove the orphaned version**: If a version should not be installable, remove it from the channel entirely
3. **Document migration path**: If users must switch channels, clearly document the process
4. **Use skipRange**: For better forward compatibility, use `skipRange` to allow direct upgrades to any future version

**Example fix for the candidate channel:**

```yaml
entries:
- name: myoperator.v1.0.0
- name: myoperator.v1.1.0
  replaces: myoperator.v1.0.0
- name: myoperator.v1.2.0
  replaces: myoperator.v1.1.0
- name: myoperator.v2.0.0
  replaces: myoperator.v1.2.0
- name: myoperator.v2.1.0
  replaces: myoperator.v2.0.0
- name: myoperator.v2.2.0
  replaces: myoperator.v2.1.0  # Added to provide upgrade path
- name: myoperator.v3.0.0
  replaces: myoperator.v2.2.0  # Continue the upgrade chain
name: candidate
package: myoperator
schema: olm.channel
```

##### Example: Orphaned versions due to missing upgrade edge

Another common cause of orphaned versions is forgetting to add an upgrade edge (like `replaces`) between versions. This creates a **disconnected upgrade graph** where there are two or more separate upgrade chains that cannot reach each other.

**Problematic FBC Configuration:**

```yaml
entries:
- name: brokenoperator.v1.0.0
- name: brokenoperator.v1.1.0
  replaces: brokenoperator.v1.0.0
- name: brokenoperator.v1.2.0
  replaces: brokenoperator.v1.1.0
# PROBLEM: v2.0.0 has no upgrade edge - missing replaces!
# This creates an orphan at v1.2.0
- name: brokenoperator.v2.0.0
- name: brokenoperator.v2.1.0
  replaces: brokenoperator.v2.0.0
name: stable
package: brokenoperator
schema: olm.channel
```

**Resulting graph:**

![Orphaned Missing Edge Graph](/docs/Reference/images/orphaned-missing-edge-graph.png)

**Critical problem**: The graph shows two disconnected upgrade chains:
- Chain 1: v1.0.0 → v1.1.0 → v1.2.0 (ORPHANED - no path forward)
- Chain 2: v2.0.0 → v2.1.0 (isolated)

Users on v1.2.0 cannot upgrade to v2.0.0 or v2.1.0 because there is no upgrade edge connecting them. This is a critical bug in the catalog.

**Fix:**

```yaml
entries:
- name: brokenoperator.v1.0.0
- name: brokenoperator.v1.1.0
  replaces: brokenoperator.v1.0.0
- name: brokenoperator.v1.2.0
  replaces: brokenoperator.v1.1.0
- name: brokenoperator.v2.0.0
  replaces: brokenoperator.v1.2.0  # FIXED: Added missing upgrade edge
- name: brokenoperator.v2.1.0
  replaces: brokenoperator.v2.0.0
name: stable
package: brokenoperator
schema: olm.channel
```

This creates a single continuous upgrade chain: v1.0.0 → v1.1.0 → v1.2.0 → v2.0.0 → v2.1.0

### Best practices

- Always visualize your upgrade graph before publishing a catalog update
- Test with `--minimum-edge` at multiple version points to ensure no orphans are created
- Look for disconnected nodes or upgrade chains in the graph visualization
- Use `skipRange` where appropriate to provide flexible upgrade paths
- Ensure all channels either reach the latest version or have a documented end-of-life plan
- Consider the impact of version restrictions on existing users
- When adding new versions, always verify they are connected to the existing upgrade graph
