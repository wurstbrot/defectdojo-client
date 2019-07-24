#!/bin/bash

PRODUCT_ID=2
SCAN_TYPE="Dependency Check Scan"
TEST_NAME_PREFIX="dep. check"

source "./env"

./pipeline.bash "$PRODUCT_ID" "master" "/home/tpagel/git/defectdojo-client/example/dependency-check-full.xml" "$SCAN_TYPE" $TEST_NAME_PREFIX
./pipeline.bash "$PRODUCT_ID" "master" "/home/tpagel/git/defectdojo-client/example/dependency-check-full-CVE-2002-2272.xml" "$SCAN_TYPE" $TEST_NAME_PREFIX

./pipeline.bash "$PRODUCT_ID" "develop" "/home/tpagel/git/defectdojo-client/example/dependency-check-full.xml" "$SCAN_TYPE" $TEST_NAME_PREFIX
./pipeline.bash "$PRODUCT_ID" "develop" "/home/tpagel/git/defectdojo-client/example/dependency-check-full-CVE-2002-2272.xml" "$SCAN_TYPE" $TEST_NAME_PREFIX

