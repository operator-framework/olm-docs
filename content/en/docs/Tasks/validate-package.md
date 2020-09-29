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


Note:  Your package can also be validated as part of adding your package to an operator-registry catalog. The operator-registry tools will verify that your operator is packaged properly ("Does it have a valid CSV of the correct format?", "Does my CRD properly reference my CSVs?", etc.).