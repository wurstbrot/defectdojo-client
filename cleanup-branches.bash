#!/bin/bash
# Author: Timo Pagel
PRODUCT_ID=$1
NAME_PREFIX=$2
BRANCHES_TO_KEEP=$3
DEFECT_DOJO_HOST_NAME="defectdojo.default.minikube.local"
API_URI="/api/v2"
DEFECTDOJO_HOST_URL="http://$DEFECT_DOJO_HOST_NAME:8080$API_URI"
MINIMAL_CRITICALITY_FOR_FINDGS=medium

if [ "$PRODUCT_ID" == "" ]; then
	echo "Parameter PRODUCT_NAME not set";
	exit 1;
fi
if [ "$NAME_PREFIX" == "" ]; then
        echo "Parameter NAME_PREFIX not set";
        exit 1;
fi
if [ "$BRANCHES_TO_KEEP" == "" ]; then
        echo "Parameter BRANCH_NAME not set";
        exit 1;
fi

function is_int() { 
	printf "%f" $1 >/dev/null 2>&1
}
API_KEY=$(curl --silent -X POST -H 'content-type: application/json' "$DEFECTDOJO_HOST_URL/api-token-auth/" -d '{"username": "admin", "password": "admin"}' | sed 's/"}//' | sed 's/{"token":"//')
echo "API KEY (v2): $API_KEY"
if [ $(echo $API_KEY | wc --chars) -ne 41 ]; then
	echo "Could not get API Key (got $(echo $API_KEY | wc --chars), expect 41)"
	exit 3
fi
ENGAGEMENTS=$(curl --silent -X GET --header 'Accept: application/json' --header 'X-CSRFToken: wrO5QWmCvfienZfkh56z9je7Zpfgv4UNfu8U8NRQHpUp3hAQ28rP8HfCCrnpbKLO' --header "Authorization: Token $API_KEY" "$DEFECTDOJO_HOST_URL/engagements/?product=$PRODUCT_ID")
DD_RANDOM=$RANDOM
echo $ENGAGEMENTS | jq '.results[].name' | sed "s#$NAME_PREFIX##" | sort | sed 's/"//g'> /tmp/DD-$DD_RANDOM
echo $BRANCHES_TO_KEEP | sed "s#$NAME_PREFIX##" | sort >> /tmp/DD2-$DD_RANDOM

diff --new-line-format="%L"  --old-line-format="" --unchanged-line-format="" /tmp/DD2-$DD_RANDOM /tmp/DD-$DD_RANDOM > /tmp/DD3-$DD_RANDOM

#Does not works with spaces in branch names
while read BRANCH ; do 
	if [ $(echo $BRANCH | grep " " | wc -l) -gt 0 ];then
		echo "the name of the branch $BRANCH includes a whitespace, skipping"
	else
#		echo "Deleting engagement/branch $BRANCH"
#		echo "$ENGAGEMENTS"
		ENGAGEMENT_ID=$(echo $ENGAGEMENTS | jq ".results[]? | select(.branch_tag == \"$BRANCH\") | .id")
		echo "Deleting engagement/branch with id $ENGAGEMENT_ID"
	RESP=$(curl --silent -X DELETE --header 'Accept: application/json' --header 'X-CSRFToken: wrO5QWmCvfienZfkh56z9je7Zpfgv4UNfu8U8NRQHpUp3hAQ28rP8HfCCrnpbKLO' --header "Authorization: Token $API_KEY" "$DEFECTDOJO_HOST_URL/engagements/$ENGAGEMENT_ID/?id=$ENGAGEMENT_ID")
	fi
done < /tmp/DD3-$DD_RANDOM
