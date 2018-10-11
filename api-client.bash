#!/bin/bash

name=$1
dt=$(date '+%Y-%m-%d %H:%M:%S')

function fillata1 {
API_KEY=$1
ENGAGEMENT_ID=$2
VERIFIED=$3
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
        --form "file=@/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report.xml" \
        --form "scan_type=Dependency Check Scan" \
        'http://localhost:8000/api/v2/import-scan/' > /dev/null
}
function fillata2 {
API_KEY=$1
ENGAGEMENT_ID=$2
VERIFIED=$3

DATA=$(cat /media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report.xml)
echo "importing for engagement $ENGAGEMENT_ID dependency-check-report-minus-AppleJavaExtensions.xml"
curl \
	--silent \
        --header 'Accept: application/json' \
        --header 'X-CSRFToken: txUiZ9ic2u5YnDIsmYv4hDDVePysE9Cv2yHHnZ6EGxmBWpwATQOe8iTZ5oKVN2Oz' \
	--form "description=Test ($dt)" \
        --header "Authorization: Token $API_KEY" \
        -H 'Content-Type: multipart/form-data; boundary=3f3faabb083d4d24bf696e1d859f2c87' \
        --form 'minimum_severity=Info' \
        --form 'skip_duplicates=false' \
        --form "verified=$VERIFIED" \
        --form "engagement=$ENGAGEMENT_ID" \
        --form 'close_old_findings=True' \
        --form "file=@/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions.xml" \
        --form "scan_type=Dependency Check Scan" \
        'http://localhost:8000/api/v2/import-scan/' > /dev/null
}

function fillata3 {
API_KEY=$1
ENGAGEMENT_ID=$2
VERIFIED=$3

echo "importing for engagement $ENGAGEMENT_ID dependency-check-report-minus-AppleJavaExtensions-minus-spring-txt.xml"
curl \
	--silent \
        --header 'Accept: application/json' \
        --header 'X-CSRFToken: txUiZ9ic2u5YnDIsmYv4hDDVePysE9Cv2yHHnZ6EGxmBWpwATQOe8iTZ5oKVN2Oz' \
        --header "Authorization: Token $API_KEY" \
        -H 'Content-Type: multipart/form-data; boundary=3f3faabb083d4d24bf696e1d859f2c87' \
        --form 'minimum_severity=Info' \
        --form "verified=$VERIFIED" \
	--form "description=Test ($dt)" \
        --form "engagement=$ENGAGEMENT_ID" \
        --form 'close_old_findings=True' \
        --form 'skip_duplicates=false' \
        --form "file=@/media/encrypted/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions-minus-spring-txt.xml" \
        --form "scan_type=Dependency Check Scan" \
        'http://localhost:8000/api/v2/import-scan/' > /dev/null
}

API_KEY=$(curl --silent -X POST -H 'content-type: application/json' http://localhost:8000/api/v2/api-token-auth/ -d '{"username": "admin", "password": "admin"}' | sed 's/"}//' | sed 's/{"token":"//')
echo "API KEY (v2): $API_KEY"

PRODUCT_RESP=$(curl --silent -X POST --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-CSRFToken: rQ1QIKFTf5Ub17v1Fsghy4Z3JjeXMoaxwZ3liAud0qSE4yNHmRxFXlIkmEoM4ZrH' --header "Authorization: Token $API_KEY" -d '{"name": "'$name'", "prod_type": "1", "description": "ProjectName' 'http://localhost:8000/api/v2/products/'  | sed 's/{"url":"http:\/\/localhost:8000\/api\/v2\/products\///' | sed 's/\/.*//')
PRODUCT_ID=$(echo $PRODUCT_RESP | sed 's/{"id"://' | sed 's/,.*//')
echo "created product with id $PRODUCT_ID"

RESP=$(curl --silent --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-CSRFToken: rQ1QIKFTf5Ub17v1Fsghy4Z3JjeXMoaxwZ3liAud0qSE4yNHmRxFXlIkmEoM4ZrH' --header "Authorization: Token $API_KEY" -X POST -d '{    "branch_tag": "develop", "version": "v1.0", "engagement_type": "CI/CD", "product": "'$PRODUCT_ID'", "name": "CI/CD dep check develop", "target_start": "2018-06-01", "target_end": "2018-06-01", "active": "True", "pen_test": "False", "check_list": "False", "threat_model": "False", "lead": 1,"status": "In Progress", "deduplication_level": "engagement"}' 'http://localhost:8000/api/v2/engagements/')

ENGAGEMENT_ID=$(echo $RESP | sed 's/{"id"://' | sed 's/,"tags.*//')
echo "created engagement (develop) with id $ENGAGEMENT_ID"
fillata1 $API_KEY $ENGAGEMENT_ID "False"
fillata2 $API_KEY $ENGAGEMENT_ID "False"

RESP=$(curl --silent --header 'Content-Type: application/json' --header 'Accept: application/json' --header 'X-CSRFToken: rQ1QIKFTf5Ub17v1Fsghy4Z3JjeXMoaxwZ3liAud0qSE4yNHmRxFXlIkmEoM4ZrH' --header "Authorization: Token $API_KEY" -X POST -d '{    "branch_tag": "master", "version": "v1.0", "engagement_type": "CI/CD", "product": "'$PRODUCT_ID'", "name": "CI/CD dep check master", "target_start": "2018-06-01", "target_end": "2018-06-01", "active": "True", "pen_test": "False", "check_list": "False", "threat_model": "False", "lead": 1,"status": "In Progress", "deduplication_level": "product"}' 'http://localhost:8000/api/v2/engagements/')

ENGAGEMENT_ID=$(echo $RESP | sed 's/{"id"://' | sed 's/,"tags.*//')
echo "created engagement (master) with id $ENGAGEMENT_ID"
fillata1 $API_KEY $ENGAGEMENT_ID "True"
fillata2 $API_KEY $ENGAGEMENT_ID "True"
fillata3 $API_KEY $ENGAGEMENT_ID "True"

