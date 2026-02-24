#!/bin/bash

while true; do
curl -s 'https://bxeregprod.oit.nd.edu/StudentRegistration/ssb/searchResults/getEnrollmentInfo' \
  -H 'Content-Type: application/x-www-form-urlencoded; charset=UTF-8' \
  -H 'X-Synchronizer-Token: YOUR_TOKEN_HERE' \
  -H 'X-Requested-With: XMLHttpRequest' \
  -H 'Origin: https://bxeregprod.oit.nd.edu' \
  -H 'Referer: https://bxeregprod.oit.nd.edu/StudentRegistration/ssb/courseSearch/courseSearch' \
  -H 'User-Agent: Mozilla/5.0' \
  --data-raw 'term=202320&courseReferenceNumber=24649' |
grep -A1 'Enrollment Seats Available' |
tail -n 1 |
sed -E 's/.*>([0-9]+)<.*/\1/'
  echo -e "\n----- Sleeping for 1 second -----"
  sleep 1
done
