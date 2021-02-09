#!/usr/bin/env bash
set -ev

CONTAINER_RUN_EXTRA_OPTIONS=${CONTAINER_RUN_EXTRA_OPTIONS:=""}
CONTAINER_ENGINE=${CONTAINER_ENGINE:="docker"}
volume_name="olm-html"

function cleanup() {
    exit_status=$?
    ${CONTAINER_ENGINE} volume rm ${volume_name}
    exit $exit_status
}
trap cleanup EXIT

${CONTAINER_ENGINE} volume create ${volume_name}
${CONTAINER_ENGINE} run --rm ${CONTAINER_RUN_EXTRA_OPTIONS} -v "$(pwd):/src" -v ${volume_name}:/src/public klakegg/hugo:0.73.0-ext-ubuntu
${CONTAINER_ENGINE} run --rm -v ${volume_name}:/target mtlynch/htmlproofer /target --empty-alt-ignore --http-status-ignore 429 --allow_hash_href
