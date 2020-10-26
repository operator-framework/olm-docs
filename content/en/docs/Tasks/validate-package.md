---
title: "Validating your package"
weight: 3
description: >
  Once you've created your operator's package manifests, you will want to ensure that your package is valid and in the correct format. 
---


## Linting

You can perform some basic static verification on your package by using [`operator-courier`](https://github.com/operator-framework/operator-courier).

```
$ pip3 install operator-courier
$ operator-courier verify manifests/my-operator-package
```

You can also use `operator-courier` to verify that your operator will be displayed properly on [OperatorHub.io](https://operatorhub.io/).

```
$ operator-courier verify --ui_validate_io manifests/my-operator-package
```


Note:  Your package can also be validated as part of adding your package to an operator-registry catalog. The operator-registry tools will verify that your operator is packaged properly ("Does it have a valid CSV of the correct format?", "Does my CRD properly reference my CSVs?", etc.).

## Validation

The [`api`](https://github.com/operator-framework/api) library contains a validation library that is used by operator-framework tooling like `operator-sdk` and `opm` to validate operator bundles. There is also a CLI tool that is included in the `api` that can be used to validate bundles called `operator-verify`. See the [usage](https://github.com/operator-framework/api#usage) for more info. Use the `operator-verify manifests </manifest-directory>` to validate all manifests in a directory. 

### Optional Validation

Some validation rules are enforced by `operator-verify` by default, while others can be enabled:
* Passing the `operatorhub_validate` flag will enable operatorhub validation on the CSV (for example, icon validation, emails of project maintainers, and more)
* Passing the `object_validate` flag will enable bundle object validation (checks objects like PodDisruptionBudgets and PriorityClasses for certain settings)
* Setting the `OPERATOR_BUNDLE_CATEGORIES` environmental variable to the path to a json file containing a list of categories will enable those categories to be used when comparing CSV categories for operatorhub validation. The json file should be in the following format:
```
{
   "categories":[
      "Cloud Pak",
      "Registry",
      "MyCoolThing",
   ]
}
```
If not set, the default categories will be used when performing operatorhub validation, found [here](https://github.com/operator-framework/api/blob/00315468e812212e3c893c469bae957251ae0308/pkg/validation/internal/operatorhub.go#L37). 