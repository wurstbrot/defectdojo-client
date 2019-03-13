#!/bin/bash

BRANCH=master

./pipeline.bash "1" "master" "/home/tpagel/git/defectdojo_api/examples/dependency/dependency-check-report.xml"
./pipeline.bash "1" "master" "/home/tpagel/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions.xml"
./pipeline.bash "1" "master" "/home/tpagel/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions-minus-spring-txt.xml"


./pipeline.bash "1" "develop" "/home/tpagel/git/defectdojo_api/examples/dependency/dependency-check-report.xml"
./pipeline.bash "1" "develop" "/home/tpagel/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions.xml"
./pipeline.bash "1" "develop" "/home/tpagel/git/defectdojo_api/examples/dependency/dependency-check-report-minus-AppleJavaExtensions-minus-spring-txt.xml"
