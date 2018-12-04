#!/bin/bash
# Author: Timo Pagel, 
UPLOAD_PATH=$1
ENGAGEMENT_ID=$2
dt=$(date '+%Y-%m-%d %H:%M:%S')
DEFECT_DOJO_HOST_NAME="defectdojo"
API_URI="/api/v2"
DEFECTDOJO_HOST_URL="http://$DEFECT_DOJO_HOST_NAME:8000$API_URI"

function filldata {
	API_KEY=$1
	ENGAGEMENT_ID=$2
	VERIFIED=$3
	LOCAL_FILE_PATH=$4
	echo "importing for engagement $ENGAGEMENT_ID dependency-check-report.xml"
	curl \
        	--silent \
	        --header 'Accept: application/json' \
	        --header 'X-CSRFToken: txUiZ9ic2u5YnDIsmYv4hDDVePysE9Cv2yHHnZ6EGxmBWpwATQOe8iTZ5oKVN2Oz' \
	        --header "Authorization: Token $API_KEY" \
	        -H 'Content-Type: multipart/form-data; boundary=3f3faabb083d4d24bf696e1d859f2c87' \
	        --form "description=Test ($dt)" \
	        --form 'minimum_severity=Info' \
	        --form "engagement=$ENGAGEMENT_ID" \
	        --form 'skip_duplicates=false' \
	        --form "verified=$VERIFIED" \
	        --form 'close_old_findings=True' \
	        --form "file=@$LOCAL_FILE_PATH" \
	        --form "scan_type=Dependency Check Scan" \
	        "$DEFECTDOJO_HOST_URL/import-scan/" > /dev/null
}

API_KEY=$(curl --silent -X POST -H 'content-type: application/json' "$DEFECTDOJO_HOST_URL/api-token-auth/" -d '{"username": "admin", "password": "admin"}' | sed 's/"}//' | sed 's/{"token":"//')
echo "API KEY (v2): $API_KEY"
if [ $(echo $API_KEY | wc --chars) -ne 41 ]; then
	echo "Could not get API Key (got $(echo $API_KEY | wc --chars), expect x)"
	exit
fi

fillata $API_KEY $ENGAGEMENT_ID "True" $UPLOAD_PATH

