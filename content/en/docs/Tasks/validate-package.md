---
title: "Validating your package"
weight: 3
description: >
  Once you've created your operator's package manifests, you will want to ensure that your package is valid and in the correct format.
---

## Linting

You can perform some basic static verification on your package by using [`operator-courier`](https://github.com/operator-framework/operator-courier).

```bash
pip3 install operator-courier
operator-courier verify manifests/my-operator-package
```

You can also use `operator-courier` to verify that your operator will be displayed properly on [OperatorHub.io](https://operatorhub.io/).

```bash
operator-courier verify --ui_validate_io manifests/my-operator-package
```

*Note*:  Your package can also be validated as part of adding your package to an operator-registry catalog. The operator-registry tools will verify that your operator is packaged properly ("Does it have a valid CSV of the correct format?", "Does my CRD properly reference my CSVs?", etc.).

## Validation

The [`api`](https://github.com/operator-framework/api) library contains a validation library that is used by operator-framework tooling like `operator-sdk` and `opm` to validate operator bundles. For more information on validating via the `operator-sdk` see the [`operator-sdk bundle validate` documentation](https://sdk.operatorframework.io/docs/cli/operator-sdk_bundle_validate/#operator-sdk-bundle-validate).

The `opm alpha bundle validate` command will validate bundle image from a remote source to determine if its format and content information are accurate.
The following validators will run by default on every invocation of the command.

- CSV validator - validates the CSV name and replaces fields.
- CRD validator - validates the CRDs OpenAPI V3 schema.
- Bundle validator - validates the bundle format and annotations.yaml file as well as the optional dependencies.yaml file.

For example:

`$ opm alpha bundle validate --tag quay.io/test/test-operator:latest --image-builder docker`

### Optional Validation

Some validators are disabled by default and can be optionally enabled via the `--optional-validators` or `-o` flag

- Operatorhub validator - performs operatorhub.io validation. To validate a bundle using custom categories use with the `OPERATOR_BUNDLE_CATEGORIES` environmental variable to point to a json-encoded categories file. Enable via `--optional-validators=operatorhub`.
- Bundle objects validator - performs validation on resources like PodDisruptionBudgets and PriorityClasses. Enable via `--optional-validators=bundle-objects`.
Multiple optional validators can be enabled at once, for example `--optional-validators=operatorhub,bundle-objects`.

#### Custom bundle categories

The operatorhub validator can verify against custom bundle categories by setting the `OPERATOR_BUNDLE_CATEGORIES` environmental variable.
Setting the `OPERATOR_BUNDLE_CATEGORIES` environmental variable to the path to a json file containing a list of categories will enable those categories to be used when comparing CSV categories for operatorhub validation. The json file should be in the following format:

```json
{
   "categories":[
      "Cloud Pak",
      "Registry",
      "MyCoolThing",
   ]
}
```

For example:

`$ OPERATOR_BUNDLE_CATEGORIES=./validate/categories.json ./bin/opm alpha bundle validate --tag <bundle-tag> --image-builder docker -o operatorhub`
will validate the bundle using the provided categories file.

If `OPERATOR_BUNDLE_CATEGORIES` is not set, and operatorhub validation is enabled, the default categories will be used when performing operatorhub validation. The default categories are the following:

- AI/Machine Learning
- Application Runtime
- Big Data
- Cloud Provider
- Developer Tools
- Database
- Integration & Delivery
- Logging & Tracing
- Monitoring
- Networking
- OpenShift Optional
- Security
- Storage
- Streaming & Messaging
