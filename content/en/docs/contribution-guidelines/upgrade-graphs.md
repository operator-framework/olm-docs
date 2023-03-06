---
title: Channel Upgrade Graphs Legends
linkTitle: Upgrade Graphs Legends
description: >
  Defines the legends for channel upgrade graph representation schemes used. 
---

This document enumerates the legends for the graphs that depict channel upgrades throughout this site. Using the legends documented here can help to communicate channel upgrade graphs in a standardized way.

## Legends

| <div style="align-text: center;width:200px">Diagram (e.g)</div> | Description |   
|----------|:-------------:|
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   ID(v0.0.1):::head
{{</mermaid>}} | Version of the operator which is the head of a channel different versions are available in |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   ID(v0.0.1):::installed
{{</mermaid>}} | Version of the operator currently installed on cluster |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   ID(v0.0.1)
{{</mermaid>}} | Operator bundle version which is installable |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   subgraph preview
      ID(v0.0.1) 
   end
{{</mermaid>}} | Operator bundle channel. |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   subgraph "preview (default)"
      ID(v0.0.1) --> ID2(v0.0.2)
   end
{{</mermaid>}} | Default Operator bundle channel. |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   A(v0.0.1) --> B(v0.0.4)
{{</mermaid>}} | An upgrade path to replace one operator bundle version for another using the [`olm.channel`][olm-channel] `replaces` field. More info: [here][upgrade-path-replaces].
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   A(v0.0.1) x--x |v0.0.2,v0.0.3| B(v0.0.4)
{{</mermaid>}}  | An upgrade path to skip versions in the upgrade path using the [`olm.channel`][olm-channel] `skips` field. More info: [here][upgrade-path-skips]. |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   C(v2.0.3) o--o |>= 2.0.4 < 3.0.0| D(v3.0.1)
{{</mermaid>}} | An upgrade path to skip a range of operator bundle versions using the [`olm.channel`][olm-channel] `skipRange` field. More info: [here][upgrade-path-skiprange]. |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   A(v0.0.1) -.-> B(v0.0.4)
{{</mermaid>}} | Represent the same replace method describe above but for a future scenario |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   A(v0.0.1) x-.-x |v0.0.2,v0.0.3| B(v0.0.4)
{{</mermaid>}} | Represent the same skips method describe above but for a future scenario |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   C(v2.0.3) o-.-o |>= 2.0.4 < 3.0.0| D(v3.0.1)
{{</mermaid>}} | Represent the same skipRange method describe above but for a future scenario |
| {{<mermaid>}}
flowchart TB
   classDef head fill:#ff668d;
   classDef installed fill:#34ebba;
 
   E(v0.0.2 \n fa:fa-tag label=value)
{{</mermaid>}} | catalog image label with its value for an operator bundle version. (eg.`LABEL com.vendor.release.versions:=v4.7`)

## Creating graphs 

The graphs are done programmatically via [mermaid](https://mermaid.js.org/). You can use its [online editor](https://mermaid.live) to work with them and check the following examples.

Check the following example: 

{{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
 
   subgraph stable
   A(v0.0.1):::installed --> B(v0.0.2)
   B(v0.0.2) x--x |v0.0.3,v0.0.4| C(v0.0.5 \n fa:fa-tag 4.6):::head
   C -.-> E(v0.0.6 \n fa:fa-tag 4.6)
   end
{{</mermaid>}}

Now, check the code used to generate this example:

```js
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
 
   subgraph stable
   A(v0.0.1):::installed --> B(v0.0.2)
   B(v0.0.2) x--x |v0.0.3,v0.0.4| C(v0.0.5 \n fa:fa-tag 4.6):::head
   C -.-> E(v0.0.6 \n fa:fa-tag 4.6)
   end
```

### Usage code

Note that, the graphs requires starts with:

```js
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
```

Following the code semantic with examples which ought to be used to create the Upgrade Graphs Diagrams. 

| Description   |      Code      |  Examples |
|----------|:-------------:|------:|
| head bundle |  `ID(<bundle tag>):::head` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   ID(v0.0.1):::head
{{</mermaid>}} |
| installed bundle |  `ID(<bundle tag>):::installed` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   ID(v0.0.1):::installed
{{</mermaid>}} |
| installable bundle | `ID(<bundle tag>)` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   ID(v0.0.1)
{{</mermaid>}} |
| channel |  `subgraph <channel name> end` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   subgraph preview
      ID(v0.0.1)
   end
{{</mermaid>}} |
| default channel | `subgraph "<channel name> (default)" end` |{{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   subgraph "preview (default)"
      ID(v0.0.1) --> ID2(v0.0.2)
   end
{{</mermaid>}} |
| replaces |`ID(<bundle tag>) --> ID(<bundle tag>)` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   A(v0.0.1) --> B(v0.0.4)
{{</mermaid>}} |
| skips | `ID(<bundle tag>) x--x \| <versions that should be skipped> \| ID(<bundle tag>)` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   A(v0.0.1) x--x |v0.0.2,v0.0.3| B(v0.0.4)
{{</mermaid>}} |
| skipRange | `ID<bundle tag>) o--o \| <range> \| ID(<bundle tag>)` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   C(v2.0.3) o--o |>= 2.0.4 < 3.0.0| D(v3.0.1)
{{</mermaid>}} |
| future replaces |`ID(<bundle tag>) -.-> ID(<bundle tag>)` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   A(v0.0.1) -.-> B(v0.0.4)
{{</mermaid>}} |
| future skips | `ID(<bundle tag>) x-.-x \| <versions that should be skipped> \| ID(<bundle tag>)` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   A(v0.0.1) x-.-x |v0.0.2,v0.0.3| B(v0.0.4)
{{</mermaid>}} |
| future skipRange | `ID<bundle tag>) o-.-o \| <range> \| ID(<bundle tag>)` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   C(v2.0.3) o-.-o |>= 2.0.4 < 3.0.0| D(v3.0.1)
{{</mermaid>}} |
| Index image label  |    `ID(<bundle tag> \n fa:fa-tag <label>=<value>)` | {{<mermaid>}}
flowchart TB
   classDef head fill:#ffbfcf;
   classDef installed fill:#34ebba;
   
   E(v0.0.2 \n fa:fa-tag label=value)
{{</mermaid>}} |

[olm-channel]:/docs/reference/file-based-catalogs/#olmchannel
[upgrade-path-replaces]:/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/#replaces
[upgrade-path-skips]:/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/#skips
[upgrade-path-skiprange]:/docs/concepts/olm-architecture/operator-catalog/creating-an-update-graph/#skiprange
