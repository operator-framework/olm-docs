#!/usr/bin/env bash
set -ev

CONTAINER_RUN_EXTRA_OPTIONS=${CONTAINER_RUN_EXTRA_OPTIONS:=""}

docker volume create olm-html
docker run --rm ${CONTAINER_RUN_EXTRA_OPTIONS} -v "$(pwd):/src" -v olm-html:/src/public klakegg/hugo:0.73.0-ext-ubuntu
docker run --rm -v olm-html:/target mtlynch/htmlproofer /target --empty-alt-ignore --http-status-ignore 429 --allow_hash_href
docker volume rm olm-html
