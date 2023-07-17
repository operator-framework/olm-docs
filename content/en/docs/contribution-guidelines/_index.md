---
title: "Contribution Guidelines"
linkTitle: "Contribution Guidelines"
weight: 7
description: >
  How to contribute to the docs
---

We use [Hugo](https://gohugo.io/) to format and generate our website, the
[Docsy](https://github.com/google/docsy) theme for styling and site structure,
and [Netlify](https://www.netlify.com/) to manage the deployment of the site.
Hugo is an open-source static site generator that provides us with templates,
content organisation in a standard directory structure, and a website generation
engine. You write the pages in Markdown (or HTML if you want), and Hugo wraps them up into a website.

All submissions, including submissions by project members, require review. We
use GitHub pull requests for this purpose. Consult
[GitHub Help](https://help.github.com/articles/about-pull-requests/) for more
information on using pull requests.

## Quick start with Netlify

Here's a quick guide to updating the docs. It assumes you're familiar with the
GitHub workflow and you're happy to use the automated preview of your doc
updates:

1. Fork [olm-docs](https://github.com/operator-framework/olm-docs) on GitHub.
1. Make your changes and send a pull request (PR).
1. If you're not yet ready for a review, create a draft PR to indicate it's a work in progress. (**Don't** add the Hugo property
  "draft = true" to the page front matter, because that prevents the
  auto-deployment of the content preview described in the next point.)
1. Wait for the automated PR workflow to do some checks. When it's ready,
  you should see a comment like this: **deploy/netlify — Deploy preview ready!**
1. Click **Details** to the right of "Deploy preview ready" to see a preview
  of your updates.
1. Continue updating your doc and pushing your changes until you're happy with
  the content.
1. When you're ready for a review, remove any "WIP" markers and mark PR ready for review.

## Updating a single page

If you've just spotted something you'd like to change while using the docs, Docsy has a shortcut for you:

1. Click **Edit this page** in the top right hand corner of the page.
1. If you don't already have an up to date fork of the project repo, you are prompted to get one - click **Fork this repository and propose changes** or **Update your Fork** to get an up to date version of the project to edit. The appropriate page in your fork is displayed in edit mode.
1. Follow the rest of the [Quick start with Netlify](#quick-start-with-netlify) process above to make, preview, and propose your changes.

## Previewing your changes locally

If you want to run your own local Hugo server to preview your changes as you work follow [this guide](/docs/contribution-guidelines/local-docs/).

## Creating an issue

If you've found a problem in the docs, but you're not sure how to fix it yourself, please create an issue in the [olm-docs repo](https://github.com/operator-framework/olm-docs). You can also create an issue about a specific page by clicking the **Create Issue** button in the top right hand corner of the page.

## Useful resources

* [Docsy user guide](https://www.docsy.dev/docs/): All about Docsy, including how it manages navigation, look and feel, and multi-language support.
* [Hugo documentation](https://gohugo.io/documentation/): Comprehensive reference for Hugo.
