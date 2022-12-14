#!/bin/sh
user="$(id -u)"
if [ "$user" -ne 0 ]; then export SUDO="sudo"; else export SUDO=""; fi
if grep "Alpine" /etc/issue > /dev/null 2>&1; then
    #shellcheck disable=1090
    . "${BASH_ENV}"
    if ! command -v jq > /dev/null 2>&1; then
        $SUDO apk update
        $SUDO apk add jq
    fi
 else
    if ! command -v jq > /dev/null 2>&1; then
        $SUDO apt update
        $SUDO apt install jq
    fi
fi

PARAM_AWS_HEALTH_REGION_TO_CHECK="$(eval echo "$PARAM_AWS_HEALTH_REGION_TO_CHECK")"

FILTER="{\"regions\": ["\"${PARAM_AWS_HEALTH_REGION_TO_CHECK}\""],\"eventTypeCategories\": [\"issue\"], \"eventStatusCodes\": [\"open\",\"upcoming\"]}"
echo "Checking Health for ${PARAM_AWS_HEALTH_REGION_TO_CHECK} region"

i=1
while [ "$i" -le "$PARAM_AWS_HEALTH_MAX_POLL_ATTEMPTS" ]
do
    echo "Poll Attempt #$i"
    AWS_EVENTS=$(aws health describe-events --filter "${FILTER}" | jq .events)
    if [ "${AWS_EVENTS}" = "[]" ]; then
        echo "No issues found in ${PARAM_AWS_HEALTH_REGION_TO_CHECK} region";
        exit 0;
    elif [ "$i" -eq "$PARAM_AWS_HEALTH_MAX_POLL_ATTEMPTS" ]; then
        echo "Max attempts reached. Issues found in ${PARAM_AWS_HEALTH_REGION_TO_CHECK} region:"
        echo "${AWS_EVENTS}"
        exit 1;
    else
        sleep 10;
        i=$((i+1))
    fi
done
