#!/bin/bash

source ./env
source ./library.bash

PRODUCT_ID=$1
NAME_PREFIX=$2
BRANCHES_TO_KEEP=$3

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
# echo "API KEY (v2): $API_KEY"
if [ $(echo $API_KEY | wc --chars) -ne 41 ]; then
	echo "Could not get API Key (got $(echo $API_KEY | wc --chars), expect 41 chars)"
	exit 3
fi
ENGAGEMENTS=$(defectdojoCurl "$DEFECTDOJO_HOST_URL/engagements/?product=$PRODUCT_ID")
DD_RANDOM=$RANDOM
echo $ENGAGEMENTS | jq '.results[].name' | sed "s#$NAME_PREFIX##" | sed 's#/#-#g' | sort | uniq | sed 's/"//g' > /tmp/existing-branches.txt
echo $BRANCHES_TO_KEEP | sed "s#$NAME_PREFIX##" | sed -e 's/\s\s*/\n/g' | sed 's#/#-#g' | sort > /tmp/branches-to-keep.txt

diff --new-line-format="%L"  --old-line-format="" --unchanged-line-format="" /tmp/branches-to-keep.txt /tmp/existing-branches.txt > /tmp/engagements-to-delete.txt

# delete engagements with no branch
while read BRANCH ; do
        if [ 0 -eq $(grep $BRANCH branches-to-keep.txt | wc -l) ]; then 
                # delete engagement ; in case there are multiple engagements with that branch name due to an error, use the last one
                ENGAGEMENT_ID=$(echo $ENGAGEMENTS | jq ".results[]? | select(.branch_tag == \"$BRANCH\") | .id" | head -n 1)
                echo "Deleting engagement/branch with id \"$ENGAGEMENT_ID\" (\"$BRANCH\")"
                RESP=$(defectdojoCurl
                        -X DELETE \
                        "$DEFECTDOJO_HOST_URL/engagements/$ENGAGEMENT_ID/?id=$ENGAGEMENT_ID")
        fi
done < /tmp/engagements-to-delete.txt
