# learn [![Build Status](https://img.shields.io/drone/build/dxas90/learn?server=https%3A%2F%2Fdrone.dxas90.xyz)](https://drone.dxas90.xyz/dxas90/learn)

![Lines of code](https://img.shields.io/tokei/lines/github/dxas90/learn)  
just to learn my stuff :)

### Binaries

[![Releases](https://img.shields.io/github/v/release/dxas90/learn.svg)](https://github.com/dxas90/learn/releases) [![Releases](https://img.shields.io/github/downloads/dxas90/learn/total.svg)](https://github.com/dxas90/learn/releases)


### Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/dxas90/learn.svg)](https://hub.docker.com/r/dxas90/learn/) [![Image Size](https://img.shields.io/docker/image-size/dxas90/learn/latest)](https://dxas90.work/pulls/dxas90)

```sh
oc new-app https://github.com/dxas90/learn.git
```

## What we want
```text
          Git Actions:                CI System Actions:

   +-------------------------+       +-----------------+
+-►| Create a Feature Branch |   +--►| Build Container |
|  +------------+------------+   |   +--------+--------+
|               |                |            |
|               |                |            |
|      +--------▼--------+       |    +-------▼--------+
|  +--►+ Push the Branch +-------+    | Push Container |
|  |   +--------+--------+            +-------+--------+
|  |            |                             |
|  |            |                             |
|  |     +------▼------+            +---------▼-----------+
|  +-----+ Test/Verify +◄-------+   | Deploy Container to |
|        +------+------+        |   | Ephemeral Namespace |
|               |               |   +---------+-----------+
|               |               |             |
|               |               +-------------+
|               |
|               |                    +-----------------+
|               |             +-----►| Build Container |
|      +--------▼--------+    |      +--------+--------+
|  +--►+ Merge to main   +----+               |
|  |   +--------+--------+                    |
|  |            |                     +-------▼--------+
|  |            |                     | Push Container |
|  |     +------▼------+              +-------+--------+
|  +-----+ Test/Verify +◄------+              |
|        +------+------+       |              |
|               |              |    +---------▼-----------+
|               |              |    | Deploy Container to |
|               |              |    | Staging   Namespace |
|               |              |    +---------+-----------+
|               |              |              |
|               |              +--------------+
|               |
|        +------▼-----+             +---------------------+
+--------+ Tag main   +------------►| Deploy Container to |
         +------------+             |     Production      |
                                    +---------------------+
```

```mermaid

flowchart TB
    A["Create a Feature Branch"]
    B["Push the Branch"]
    C["Test / Verify"]
    D["Merge to main"]
    E["Test / Verify"]
    F["Tag main"]

    G["Build Container"]
    H["Push Container"]
    I["Deploy to<br/>Ephemeral Namespace"]

    J["Build Container"]
    K["Push Container"]
    L["Deploy to<br/>Staging Namespace"]

    M["Deploy to<br/>Production"]

    A --> B --> C --> D --> E --> F

    G --> H --> I
    J --> K --> L

    A --> G
    B --> H
    I --> C

    D --> J
    L --> E
    F --> M

    C -.->|Retry| B
    E -.->|Retry| D
    F -.->|Next Feature| A

    I ~~~ J
    L ~~~ M

    classDef git fill:#dbeafe,stroke:#2563eb,color:#1e40af
    classDef ci fill:#dcfce7,stroke:#16a34a,color:#166534
    classDef production fill:#fef3c7,stroke:#d97706,color:#92400e

    class A,B,C,D,E,F git
    class G,H,I,J,K,L ci
    class M production
```

```text
  Create Branch ──┬──> Build Container
                  │
  Push ──────┬────┼──> Push Container -> Deploy Ephemeral
             │    │                            │
             └──> Test/Verify <────────────────┘
                       │
                  Merge to main
                       │
                       ├──> Build Container -> Push Container -> Deploy Staging
                       │                                            │
                       └──> Test/Verify <───────────────────────────┘
                                  │
                             Tag main -> Deploy Production
```

### LICENCE

![GitHub](https://img.shields.io/github/license/dxas90/learn)
