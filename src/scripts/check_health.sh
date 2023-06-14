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

ORB_STR_REGION_TO_CHECK="$(circleci env subst "${ORB_STR_REGION_TO_CHECK}")"
ORB_STR_PROFILE="$(circleci env subst "${ORB_STR_PROFILE}")"


FILTER="{\"regions\": ["\"${ORB_STR_REGION_TO_CHECK}\""],\"eventTypeCategories\": [\"issue\"], \"eventStatusCodes\": [\"open\",\"upcoming\"]}"
echo "Checking Health for ${ORB_STR_REGION_TO_CHECK} region"

i=1
while [ "$i" -le "$ORB_INT_MAX_POLL_ATTEMPTS" ]
do
    echo "Poll Attempt #$i"
    AWS_EVENTS=$(aws health describe-events --filter "${FILTER}" --profile "${ORB_STR_PROFILE}" | jq .events)
    if [ "${AWS_EVENTS}" = "[]" ]; then
        echo "No issues found in ${ORB_STR_REGION_TO_CHECK} region";
        exit 0;
    elif [ "$i" -eq "$ORB_INT_MAX_POLL_ATTEMPTS" ]; then
        echo "Max attempts reached. Issues found in ${ORB_STR_REGION_TO_CHECK} region:"
        echo "${AWS_EVENTS}"
        exit 1;
    else
        sleep 10;
        i=$((i+1))
    fi
done
