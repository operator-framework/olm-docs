#!/usr/bin/env bash
set -ev

CONTAINER_RUN_EXTRA_OPTIONS=${CONTAINER_RUN_EXTRA_OPTIONS:=""}
CONTAINER_ENGINE=${CONTAINER_ENGINE:="docker"}

# TODO(tflannag): We may need to trap that `... volume rm` call.
${CONTAINER_ENGINE} volume create olm-html
${CONTAINER_ENGINE} run --rm ${CONTAINER_RUN_EXTRA_OPTIONS} -v "$(pwd):/src" -v olm-html:/src/public klakegg/hugo:0.73.0-ext-ubuntu
${CONTAINER_ENGINE} run --rm -v olm-html:/target mtlynch/htmlproofer /target --empty-alt-ignore --http-status-ignore 429 --allow_hash_href
${CONTAINER_ENGINE} volume rm olm-html
