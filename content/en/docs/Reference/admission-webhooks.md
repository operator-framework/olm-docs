---
title: "Admission Webhook Reference"
linkTitle: "Admission Webhook Reference"
weight: 3
date: 2020-04-24
---

After a request has been authenticated and authorized, admission webhooks intercept requests against the Kubernetes API and have an opportunity to validate or update the object before it is saved in the object store. Please refer to the following table that highlights what each webhook is capable of:

|                    | Validating Webhooks | Mutating Webhooks |
|--------------------|---------------------|-------------------|
| Validating Objects |          x          |         x         |
| Mutating Objects   |                     |         x         |

If you are interested in learning more about admission webhooks, please review the [official kubernetes documentation](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/#what-are-they).
