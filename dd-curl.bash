#!/bin/bash

#CONTENT_TYPE=""
if [ $(echo "$@" | grep Content-Type | wc -l) -eq 0 ]; then
    CONTENT_TYPE="--header 'Content-Type: application/json'"
fi
echo $CONTENT_TYPE
exit;
curl \
    --insecure \
    --silent \
    --header 'Accept: application/json' \
    --header 'X-CSRFToken: X' \
    $CONTENT_TYPE \
    --header "Authorization: Token $API_KEY" \
    "$@"