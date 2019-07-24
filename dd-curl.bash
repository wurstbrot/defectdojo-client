#!/bin/bash

CONTENT_TYPE="X-Header: nothing"
if [ $(echo "$@" | grep Content-Type | wc -l) -eq 0 ]; then
    CONTENT_TYPE="Content-Type: application/json"
fi

curl \
    --insecure \
    --silent \
    --header 'Accept: application/json' \
    --header 'X-CSRFToken: X' \
    --header "${CONTENT_TYPE}" \
    --header "Authorization: Token $API_KEY" \
    "$@"