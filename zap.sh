#!/bin/bash

# first run this
# chmod 777 $(pwd)
echo $(id -u):$(id -g)
mkdir -p owasp-zap-report
zap-api-scan.py -t $1:$3/v3/api-docs -f openapi -r zap_report.html

exit_code=$?

# comment above cmd and uncomment below lines to run with CUSTOM RULES
# docker run -v $(pwd):/zap/wrk/:rw -t owasp/zap2docker-weekly zap-api-scan.py -t $applicationURL:$PORT/v3/api-docs -f openapi -c zap-rules -w report.md -J json_report.json -r zap_report.html

# HTML Report
ls -ltr
# cat zap.out


echo "Exit Code : $exit_code"

if [[ ${exit_code} -ne 0 ]];  then
    echo "OWASP ZAP Report has either Low/Medium/High Risk. Please check the HTML Report"
    exit 1;
else
    echo "OWASP ZAP did not report any Risk"
fi;