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
|  +--►+ Merge to Master +----+               |
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
+--------+ Tag Master +------------►| Deploy Container to |
         +------------+             |     Production      |
                                    +---------------------+
```

### LICENCE

![GitHub](https://img.shields.io/github/license/dxas90/learn)
