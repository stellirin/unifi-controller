#!/bin/bash

get_status() {
    curl \
        --connect-timeout 1 \
        --output /dev/null \
        --silent \
        --write-out "%{HTTP_CODE}" \
        http://localhost:8080/status
}

COUNT=10
HTTP_CODE=$(get_status)
for COUNT in `seq 1 ${COUNT}`
do
    echo "HTTP_CODE: ${HTTP_CODE}"
    if [[ "${HTTP_CODE}" != "200" ]]
    then
        sleep 1
        HTTP_CODE=$(get_status)
    else
        break
    fi
done
if [ "${HTTP_CODE}" != "200" ]; then
    exit 1
fi

exit 0
