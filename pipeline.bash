#!/bin/bash
# Author: Timo Pagel
PRODUCT_ID=$1
BRANCH_NAME=$2
PATH_TO_REPORT=$3
dt=$(date '+%Y-%m-%d %H:%M:%S')
d=$(date '+%Y-%m-%d')
DEFECT_DOJO_HOST_NAME="defectdojo.default.minikube.local"
API_URI="/api/v2"
DEFECTDOJO_HOST_URL="http://$DEFECT_DOJO_HOST_NAME:8080$API_URI"
PRODUCT_HYPERLINK="$API_URI/products/$PRODUCT_ID/"
MINIMAL_CRITICALITY_FOR_FINDGS=medium

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
	echo "importing for engagement $ENGAGEMENT_ID $PATH_TO_REPORT"
	RESP=$(curl \
        	--silent \
	        --header 'Accept: application/json' \
	        --header 'X-CSRFToken: txUiZ9ic2u5YnDIsmYv4hDDVePysE9Cv2yHHnZ6EGxmBWpwATQOe8iTZ5oKVN2Oz' \
	        --header "Authorization: Token $API_KEY" \
	        -H 'Content-Type: multipart/form-data; boundary=3f3faabb083d4d24bf696e1d859f2c87' \
	        --form "description=Test ($dt)" \
	        --form 'minimum_severity=Info' \
	        --form "engagement=$ENGAGEMENT_ID" \
	        --form 'skip_duplicates=false' \
                --form 'active=true' \
	        --form "verified=$VERIFIED" \
	        --form "lead=1" \
	        --form 'close_old_findings=True' \
	        --form "file=@$PATH_TO_REPORT" \
	        --form "scan_type=Dependency Check Scan" \
                --form "scan_date=$d" \
		"$DEFECTDOJO_HOST_URL/import-scan/" )
	if [ "$(echo $RESP | jq '.scan_date')" == "" ]; then
		echo "Could not import $PATH_TO_REPORT"
		echo $RESP;
		exit 1
	fi

	RESP=$(curl -X GET --silent \
		--header 'Accept: application/json' \
                --header 'X-CSRFToken: txUiZ9ic2u5YnDIsmYv4hDDVePysE9Cv2yHHnZ6EGxmBWpwATQOe8iTZ5oKVN2Oz' \
                --header "Authorization: Token $API_KEY" \
 "$DEFECTDOJO_HOST_URL/findings/?false_p=false&serverity=$MINIMAL_CRITICALITY_FOR_FINDGS&duplicate=false&test__engagement=$ENGAGEMENT_ID")
	echo $RESP
	COUNT=$(echo $RESP | grep count  | sed 's#{"count":##' | sed 's#,.*##')
	if [ "$COUNT" != "0" ]; then
		echo "$COUNT unhandled vulnerabilties with crit. $MINIMAL_CRITICALITY_FOR_FINDGS or higher detected"
		exit 1
	else
		echo "No vulnerabilities detected"
		exit 0
	fi
}
function is_int() { 
	printf "%f" $1 >/dev/null 2>&1
}
API_KEY=$(curl --silent -X POST -H 'content-type: application/json' "$DEFECTDOJO_HOST_URL/api-token-auth/" -d '{"username": "admin", "password": "admin"}' | sed 's/"}//' | sed 's/{"token":"//')
echo "API KEY (v2): $API_KEY"
if [ $(echo $API_KEY | wc --chars) -ne 41 ]; then
	echo "Could not get API Key (got $(echo $API_KEY | wc --chars), expect 41)"
	exit 3
fi

echo "PRODUCT $PRODUCT_ID"
RESP=$(curl --silent -X GET --header 'Accept: application/json' --header "Authorization: Token $API_KEY" "$DEFECTDOJO_HOST_URL/engagements/?product=$PRODUCT_ID")
if [ $(echo $RESP | grep $BRANCH_NAME | wc -l) -eq 0 ]; then
	RESP=$(curl --silent --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-CSRFToken: rQ1QIKFTf5Ub17v1Fsghy4Z3JjeXMoaxwZ3liAud0qSE4yNHmRxFXlIkmEoM4ZrH' --header "Authorization: Token $API_KEY" -X POST -d '{    "branch_tag": "'$BRANCH_NAME'", "version": "v1.0", "engagement_type": "CI/CD", "product": "'$PRODUCT_ID'", "name": "CI/CD dep check '$BRANCH_NAME'", "target_start": "2018-06-01", "target_end": "2018-06-01", "active": "True", "pen_test": "False", "check_list": "False", "threat_model": "False", "status": "In Progress", "deduplication_on_engagement": "True", "lead": "1"}' "$DEFECTDOJO_HOST_URL/engagements/")
	echo "created engagement ($BRANCH_NAME)"
fi
ENGAGEMENT_ID=$(echo $RESP | jq '.results[]? | select(.branch_tag == "'$BRANCH_NAME'") | .id')
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

VERIFIED="False"
if [ "$BRANCH_NAME" == "master" ]; then
	VERIFIED="True"
fi

filldata $API_KEY $ENGAGEMENT_ID "$VERIFIED" "$PATH_TO_REPORT"
