#!/bin/sh
PARAM_AWS_HEALTH_REGION_TO_CHECK=$(eval echo "\$$PARAM_AWS_HEALTH_REGION_TO_CHECK")

FILTER="{\"regions\": ["\"${PARAM_AWS_HEALTH_REGION_TO_CHECK}\""],\"eventTypeCategories\": [\"issue\"], \"eventStatusCodes\": [\"open\",\"upcoming\"]}"
echo "Checking Health for ${PARAM_AWS_HEALTH_REGION_TO_CHECK} region"

i=0
while [ "$i" -lt "$PARAM_AWS_HEALTH_MAX_POLL_ATTEMPTS" ]
do
    echo "Poll Attempt #$i"
    AWS_EVENTS=$(aws health describe-events --filter "${FILTER}" | jq .events)
    if [ "${AWS_EVENTS}" = "[]" ]; then
        echo "No issues found in ${PARAM_AWS_HEALTH_REGION_TO_CHECK} region";
        exit 0;
    elif [ i = "$PARAM_AWS_HEALTH_MAX_POLL_ATTEMPTS" ]; then
        echo "Max attempts reached. Issues found in ${PARAM_AWS_HEALTH_REGION_TO_CHECK} region:"
        echo "${AWS_EVENTS}"
        exit 1;
    else
        sleep 10;
        i=$((i+1))
    fi

done
