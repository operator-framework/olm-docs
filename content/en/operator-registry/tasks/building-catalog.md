---
title: "Building a Catalog of Operators"
linkTitle: "Building a Catalog of Operators"
date: 2020-03-25
weight: 3
description: >
  Packaging an operator using a Dockerfile 
---


The below dockerfile provides an example of using the `initializer` and `registry-server` to build a minimal container that provides a `gRPC` API over the example manifests in manifests.

```Dockerfile
FROM quay.io/operator-framework/upstream-registry-builder as builder

COPY manifests manifests
RUN ./bin/initializer -o ./bundles.db

FROM scratch
COPY --from=builder /build/bundles.db /bundles.db
COPY --from=builder /build/bin/registry-server /registry-server
COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe
EXPOSE 50051
ENTRYPOINT ["/registry-server"]
CMD ["--database", "bundles.db"]
```

You can then use your favorite container building tool to generate an operator image
```shell script
docker build -t example-registry:latest -f upstream-example.Dockerfile .
docker push example-registry:latest
```
