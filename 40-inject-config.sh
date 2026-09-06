#!/bin/sh
# Runs automatically at container start (nginx's official entrypoint executes
# every script in /docker-entrypoint.d/ before nginx starts). Substitutes the
# NOCODB_* environment variables from docker-compose.yml into config.js,
# which index.html loads before the app itself runs.
set -eu
envsubst '${NOCODB_URL} ${NOCODB_TOKEN} ${NOCODB_BOXES_ID} ${NOCODB_ITEMS_ID} ${NOCODB_LINK_FIELD}' \
  < /usr/share/nginx/html/config.js.template \
  > /usr/share/nginx/html/config.js
