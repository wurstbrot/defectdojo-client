#!/bin/bash
# Author: Timo Pagel, 
name=$1
dt=$(date '+%Y-%m-%d %H:%M:%S')
d=$(date '+%Y-%m-%d')
DEFECT_DOJO_HOST_NAME="defectdojo"
API_URI="/api/v2"
DEFECTDOJO_HOST_URL="http://$DEFECT_DOJO_HOST_NAME:8000$API_URI"

function filldata {
	API_KEY=$1
	ENGAGEMENT_ID=$2
	VERIFIED=$3
	LOCAL_FILE_PATH=$4
	echo "importing for engagement $ENGAGEMENT_ID $LOCAL_FILE_PATH"
	RESP=$(curl \
        	--silent \
	        --header 'Accept: application/json' \
	        --header 'X-CSRFToken: txUiZ9ic2u5YnDIsmYv4hDDVePysE9Cv2yHHnZ6EGxmBWpwATQOe8iTZ5oKVN2Oz' \
	        --header "Authorization: Token $API_KEY" \
	        -H 'Content-Type: multipart/form-data; boundary=3f3faabb083d4d24bf696e1d859f2c87' \
	        --form "description=Test ($dt)" \
	        --form 'minimum_severity=Info' \
	        --form "engagement=$API_URI/engagements/$ENGAGEMENT_ID/" \
	        --form 'skip_duplicates=false' \
	        --form "verified=$VERIFIED" \
	        --form "scan_date=$d" \
	        --form "lead=/api/v2/users/1/" \
	        --form 'close_old_findings=True' \
	        --form "file=@/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions-minus-spring-txt.xml" \
	        --form "scan_type=Dependency Check Scan" \
		"$DEFECTDOJO_HOST_URL/import-scan/" )

	RESP=$(curl -X GET --silent \
		--header 'Accept: application/json' \
                --header 'X-CSRFToken: txUiZ9ic2u5YnDIsmYv4hDDVePysE9Cv2yHHnZ6EGxmBWpwATQOe8iTZ5oKVN2Oz' \
                --header "Authorization: Token $API_KEY" \
 "$DEFECTDOJO_HOST_URL/findings/?false_p=false&severity=Medium&duplicate=false&test__engagement=$ENGAGEMENT_ID")
	COUNT=$(echo $RESP | grep count  | sed 's#{"count":##' | sed 's#,.*##')
	if [ "$COUNT" != "0" ]; then
		echo "$COUNT unhandled vulnerabilties detected"
		exit;
	fi
}
function is_int() { 
	printf "%f" $1 >/dev/null 2>&1
}
API_KEY=$(curl --silent -X POST -H 'content-type: application/json' "$DEFECTDOJO_HOST_URL/api-token-auth/" -d '{"username": "admin", "password": "admin"}' | sed 's/"}//' | sed 's/{"token":"//')
echo "API KEY (v2): $API_KEY"
if [ $(echo $API_KEY | wc --chars) -ne 41 ]; then
	echo "Could not get API Key (got $(echo $API_KEY | wc --chars), expect x)"
	exit
fi

PRODUCT_RESP=$(curl --silent -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-CSRFToken: rQ1QIKFTf5Ub17v1Fsghy4Z3JjeXMoaxwZ3liAud0qSE4yNHmRxFXlIkmEoM4ZrH' --header "Authorization: Token $API_KEY" -d '{"name": "'$name'", "prod_type": "1", "description": "'$name'"}' "$DEFECTDOJO_HOST_URL/products/" )
PRODUCT_ID=$(echo $PRODUCT_RESP | sed "s#{\"url\":\"$DEFECTDOJO_HOST_URL/products/##" | sed 's/\/".*//')
if ! is_int $PRODUCT_ID; then
	echo "Could not create product $name"
	echo "RESPONSE: $PRODUCT_RESP"
	exit 1;
fi
echo "created product with id $PRODUCT_ID"
PRODUCT_HYPERLINK="$API_URI/products/$PRODUCT_ID/"
RESP=$(curl --silent --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-CSRFToken: rQ1QIKFTf5Ub17v1Fsghy4Z3JjeXMoaxwZ3liAud0qSE4yNHmRxFXlIkmEoM4ZrH' --header "Authorization: Token $API_KEY" -X POST -d '{    "branch_tag": "develop", "version": "v1.0", "engagement_type": "CI/CD", "product": "'$PRODUCT_HYPERLINK'", "name": "CI/CD dep check develop", "target_start": "2018-06-01", "target_end": "2018-06-01", "active": "True", "pen_test": "False", "check_list": "False", "threat_model": "False", "status": "In Progress", "deduplication_on_engagement": "True", "lead": "/api/v2/users/1/"}' "$DEFECTDOJO_HOST_URL/engagements/")

ENGAGEMENT_ID=$(echo $RESP | sed "s#{\"url\":\"$DEFECTDOJO_HOST_URL/engagements/##" | sed 's#/.*##')
echo "ENGAGEMENT_ID $ENGAGEMENT_ID"
if ! is_int $ENGAGEMENT_ID; then
        echo "Could not create engagement for product $PRODUCT_ID"
        echo "RESPONSE: $RESP"
        exit 1;
fi

echo "created engagement (develop) with id $ENGAGEMENT_ID"
#filldata $API_KEY $ENGAGEMENT_ID "False"  "/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report.xml"
filldata $API_KEY $ENGAGEMENT_ID "False" "/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions.xml"


RESP=$(curl --silent --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-CSRFToken: rQ1QIKFTf5Ub17v1Fsghy4Z3JjeXMoaxwZ3liAud0qSE4yNHmRxFXlIkmEoM4ZrH' --header "Authorization: Token $API_KEY" -X POST -d '{    "branch_tag": "master", "version": "v1.0", "engagement_type": "CI/CD", "product": "'$PRODUCT_HYPERLINK'", "name": "CI/CD dep check master", "target_start": "2018-06-01", "target_end": "2018-06-01", "active": "True", "pen_test": "False", "check_list": "False", "threat_model": "False", "status": "In Progress", "deduplication_on_engagement": "True", "lead": "/api/v2/users/1/"}' "$DEFECTDOJO_HOST_URL/engagements/")

ENGAGEMENT_ID=$(echo $RESP | sed "s#{\"url\":\"$DEFECTDOJO_HOST_URL/engagements/##" | sed 's#/.*##')
echo "created engagement (master) with id $ENGAGEMENT_ID"
#filldata $API_KEY $ENGAGEMENT_ID "True" "/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report.xml"
filldata $API_KEY $ENGAGEMENT_ID "True" "/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions.xml"
filldata $API_KEY $ENGAGEMENT_ID "True" "/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions-minus-spring-txt.xml"



