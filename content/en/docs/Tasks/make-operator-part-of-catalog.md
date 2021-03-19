---
title: "Making your operator part of a catalog"
date: 2017-01-05
weight: 4
description: >
    Make your operator available as part of a catalog
---

Once you've packaged your operator for OLM, you can make it a part of a catalog, which is then queried to list the operators available to be installed with OLM in the cluster.

The [operator-registry project](https://github.com/operator-framework/operator-registry) defines a format for storing sets of operators and exposing them to make them available on a cluster. The simplest way to test that your package can be added to a catalog is by actually attempting to create a catalog that includes your operator.

To create a catalog that includes your package, simply build a container image that uses the operator-registry command line tools to generate a registry and serve it. For example, create a file in the root of your project called `registry.Dockerfile`

```Dockerfile
FROM quay.io/operator-framework/upstream-registry-builder as builder

COPY manifests manifests
RUN ./bin/initializer -o ./bundles.db

FROM scratch
COPY --from=builder /bundles.db /bundles.db
COPY --from=builder /bin/registry-server /registry-server
COPY --from=builder /bin/grpc_health_probe /bin/grpc_health_probe
EXPOSE 50051
ENTRYPOINT ["/registry-server"]
CMD ["--database", "bundles.db"]
```

This Dockerfile assumes that your package is in a directory called `./manifests/` similar to [this example](https://github.com/operator-framework/operator-registry/tree/master/manifests). It copies your manifests into the builder image, runs `initializer`, then copies the output into the final scratch image and defines the run command to serve the operator-registry.

Then just use your favorite container tooling to build the container image and push it to a registry:

```bash
docker build -t example-registry:latest -f registry-Dockerfile .
docker push example-registry:latest
```

Your catalog is published and we are ready to use it on your cluster.
