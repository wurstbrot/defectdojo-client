#!/bin/bash

PRODUCT_ID=4
./pipeline.bash "$PRODUCT_ID" "master" "/home/tpagel/git/defectdojo-client/example/dependency-check-full.xml" "Dependency Check Scan" "dep. check"
./pipeline.bash "$PRODUCT_ID" "master" "/home/tpagel/git/defectdojo-client/example/dependency-check-full-CVE-2002-2272.xml" "Dependency Check Scan" "dep. check"

./pipeline.bash "$PRODUCT_ID" "develop" "/home/tpagel/git/defectdojo-client/example/dependency-check-full.xml" "Dependency Check Scan" "dep. check"
./pipeline.bash "$PRODUCT_ID" "develop" "/home/tpagel/git/defectdojo-client/example/dependency-check-full-CVE-2002-2272.xml" "Dependency Check Scan" "dep. check"

