#!/bin/bash

PRODUCT_ID=$1
BRANCH_NAME=$2
PATH_TO_REPORT=$3
SCAN_TYPE=$4
TEST_NAME_PREFIX=$5


source ./env

if [ "$PRODUCT_ID" == "" ]; then
	echo "Parameter PRODUCT_NAME not set";
	exit 1;
fi
if [ "$BRANCH_NAME" == "" ]; then
        echo "Parameter BRANCH_NAME not set";
        exit 1;
fi
if [ "PATH_TO_REPORT" == "" ]; then
        echo "Parameter PATH_TO_REPORT not set";
        exit 1;
fi

function filldata {
	API_KEY=$1
	ENGAGEMENT_ID=$2
	VERIFIED=$3
	PATH_TO_REPORT=$4
	SCAN_TYPE=$5

	echo "importing for engagement $ENGAGEMENT_ID the file $PATH_TO_REPORT"
	RESP=$(./dd-curl.bash \
	        --header 'Content-Type: multipart/form-data; boundary=3f3faabb083d4d24bf696e1d859f2c87' \
	        --form "description=Test ($dt)" \
	        --form 'minimum_severity=Info' \
	        --form "engagement=$ENGAGEMENT_ID" \
	        --form 'skip_duplicates=false' \
            --form 'active=true' \
	        --form "verified=$VERIFIED" \
	        --form "lead=1" \
	        --form 'close_old_findings=True' \
	        --form "file=@$PATH_TO_REPORT" \
	        --form "scan_type=$SCAN_TYPE" \
            --form "scan_date=$d" \
		"$DEFECTDOJO_HOST_URL/import-scan/" )
		
	SCAN_DATE=$(echo $RESP | jq '.scan_date');
	if [ "$SCAN_DATE" == "" ] || [ "$SCAN_DATE" == "null" ]; then
		echo "Could not import $PATH_TO_REPORT"
		echo $RESP;
		exit 1
	fi

	for CRITICALITY_FOR_FINDGS in $CRITICALITIES_FOR_FINDGS; do
		RESP=$(./dd-curl.bash \
				-X GET \
				"$DEFECTDOJO_HOST_URL/findings/?active=true&false_p=false&serverity=$CRITICALITY_FOR_FINDGS&duplicate=false&test__engagement=$ENGAGEMENT_ID")
		#echo $RESP | jq '.results[] | select(.severity | contains("'$CRITICALITY_FOR_FINDGS'"))'
		COUNT=$(echo $RESP | jq '.results[] | select(.severity | contains("'$CRITICALITY_FOR_FINDGS'")) | .severity' | wc -l)
		if [ "$COUNT" != "0" ]; then
			echo "Found $COUNT unhandled vulnerabilties with criticality. $CRITICALITY_FOR_FINDGS detected"
			exit 1
		else
			echo "No vulnerabilities with criticality \"$CRITICALITY_FOR_FINDGS\" detected"
		fi
	done
}
function is_int() { 
	printf "%f" $1 >/dev/null 2>&1
}

#echo "API KEY (v2): $API_KEY"
if [ $(echo $API_KEY | wc --chars) -ne 41 ]; then
	echo "Could not get API Key (got $(echo $API_KEY | wc --chars), expect 41)"
	exit 3
fi

RESP=$(./dd-curl.bash \
	-X GET \
	"$DEFECTDOJO_HOST_URL/products/$PRODUCT_ID/?id=$PRODUCT_ID")
FETCHED_PRODUCT_ID=$(echo $RESP | jq '.id')
if ! is_int $FETCHED_PRODUCT_ID ; then
	echo "Could not get product id $PRODUCT_ID, does it exists?"
	exit 1;
fi

RESP=$(./dd-curl.bash \
	-X GET \
	"$DEFECTDOJO_HOST_URL/engagements/?product=$PRODUCT_ID")

if [ $(echo $RESP | jq '.results[]? | select(.branch_tag == "'$BRANCH_NAME'")' | wc -l) -eq 0 ]; then
	RESP=$(./dd-curl.bash \
    	-X POST \
        -d '{"branch_tag": "'$BRANCH_NAME'", "version": "v1.0", "engagement_type": "CI/CD", "product": "'$PRODUCT_ID'", "name": "'$TEST_NAME_PREFIX' '$BRANCH_NAME'", "target_start": "'$d'", "target_end": "2118-06-01", "active": "True", "pen_test": "False", "check_list": "False", "threat_model": "False", "status": "In Progress", "deduplication_on_engagement": "True", "lead": "1"}' \
    	"$DEFECTDOJO_HOST_URL/engagements/"
    )
fi
# in case there are multiple engagements with that branch name due to an error, use the last one
ENGAGEMENT_ID=$(echo $RESP | jq '.results[]? | select(.branch_tag == "'$BRANCH_NAME'") | .id' | head -n 1)

if ! is_int $ENGAGEMENT_ID; then
	ENGAGEMENT_ID=$(echo $RESP | jq '.id')
fi
#is_int doesn't applies to empty string
if [ "$ENGAGEMENT_ID" == "" ]; then
	ENGAGEMENT_ID=$(echo $RESP | jq '.id')
fi
if ! is_int $ENGAGEMENT_ID; then
        echo "Could not create engagement for product $PRODUCT_ID"
        echo "RESPONSE: $RESP"
        exit 1;
fi
echo "fetched engagement ($BRANCH_NAME) with id $ENGAGEMENT_ID"

VERIFIED="true"
filldata "$API_KEY" "$ENGAGEMENT_ID" "$VERIFIED" "$PATH_TO_REPORT" "$SCAN_TYPE"
