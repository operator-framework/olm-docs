---
title: "OLM Performance Profiling Instrumentation"
weight: 10
description: >
  The goal of this document is to familiarize you with the steps to enable and review OLM's performance profiling instrumentation.
---

## Prerequisites 

- [go](https://golang.org/dl/)

## Background

OLM utilizes the [pprof package](https://golang.org/pkg/net/http/pprof/) from the standard go library to expose performance profiles for the OLM and Catalog Operator. 

Due to the sensitive nature of profiling data, the profiling endpoints will reject any clients that do not present a verifiable certificate. Both operators must be configured with a serving certificate and a client CA bundle in order to access the profiling endpoints.

This document will dive into the steps to [enable olm performance profiling](#enabling-performance-profiling) and retrieving pprof data from each component.

## Enabling Performance Profiling

### Creating a Certificate

A valid server certificate must be created for each component before the Performance Profiling functionality can be enabled. If you are unfamiliar with certificate generation, we recommend using the [OpenSSL](https://www.openssl.org/) tool-kit and refer to the [request certificate](https://www.openssl.org/docs/man1.1.1/man1/openssl-req.html) documentation.

Once you have generated a private and public key, this data should be stored in a `TLS Secret`:

```bash
$ export PRIVATE_KEY_FILENAME=private.key # Replace with the name of the file that contains the private key you generated.
$ export PUBLIC_KEY_FILENAME=certificate.crt # Replace with the name of the file that contains the public key you generated.

$ kubectl -n my-namespace create secret tls my-name --cert=$PUBLIC_KEY_FILENAME --key=$PRIVATE_KEY_FILENAME
```

### Updating OLM to Use the TLS Secret

Patch the OLM or Catalog Deployment's pod template to use the generated TLS secret:

- Defining a volume and volumeMount
- Adding the `client-ca`, `tls-key` and `tls-cert` arguments
- Replacing all mentions of port `8080` with `8443`
- Updating the `livenessProbe` and `readinessProbe` to use HTTPS as the scheme

The steps to patch an existing OLM deployment can be seen below:

```bash
$ export TLS_SECRET=my-tls-secret
$ export CERT_PATH=/var/run/secrets # Define where to mount the certs.
# Set Deployment name to olm-operator or catalog-operator
$ export DEPLOYMENT_NAME=olm-operator

$ kubectl patch deployment $DEPLOYMENT_NAME -n olm --type json -p='[
    # Mount the secret to the pod
    {"op": "add", "path": "/spec/template/spec/volumes", "value":[{"name": '$TLS_SECRET', "secret": {"secretName": '$TLS_SECRET'}}]},
    {"op": "add", "path": "/spec/template/spec/containers/0/volumeMounts", "value":[{"name": '$TLS_SECRET', "mountPath": '$CERT_PATH'}]},
    
    # Add startup arguments
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--client-ca"},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"'$CERT_PATH'/tls.crt"},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--tls-key"},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"'$CERT_PATH'/tls.key"},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"--tls-cert"},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value":"'$CERT_PATH'/tls.crt"},
    
    # Replace port 8080 with 8443
    {"op": "replace", "path": "/spec/template/spec/containers/0/ports/0", "value":{"containerPort": 8443}},
    {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/port", "value":8443},
    {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/port", "value":8443},

    # Update livenessProbe and readinessProbe to use HTTPS
    {"op": "replace", "path": "/spec/template/spec/containers/0/readinessProbe/httpGet/scheme", "value":"HTTPS"},
    {"op": "replace", "path": "/spec/template/spec/containers/0/livenessProbe/httpGet/scheme", "value":"HTTPS"},
]'
deployment.apps/olm-operator patched

```

## Accessing PPROF Data

You will need to be able to access OLM port, for dev purposes the following commands may prove useful:

```bash
# Set Deployment name to olm-operator or catalog-operator
$ export DEPLOYMENT_NAME=olm-operator
$ kubectl port-forward deployment/$DEPLOYMENT_NAME 8443:8443 -n olm
```

You can then curl the OLM `/debug/pprof` endpoint to retrieve default pprof profiles like so:

```bash
$ curl https://localhost:8443/debug/pprof/heap --cert certificate.crt --key private.key  --insecure -o olm-heap

$ go tool pprof --top olm-heap
```

Please review [the official pprof documentation](https://blog.golang.org/pprof) to learn more about pprof.
