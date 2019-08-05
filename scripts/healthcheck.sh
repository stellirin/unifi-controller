#!/bin/sh

MAX_WAIT=60
HTTP_CODE=$(curl -s --connect-timeout 1 -o /dev/null -w "%{HTTP_CODE}" http://localhost:8080/status)
for i in `seq 1 ${MAX_WAIT}` ; do
    if [ "${HTTP_CODE}" != "200" ]; then
        sleep 1
        HTTP_CODE=$(curl -s --connect-timeout 1 -o /dev/null -w "%{HTTP_CODE}" http://localhost:8080/status)
    else
        break
    fi
done
if [ "${HTTP_CODE}" != "200" ]; then
    exit 1
fi

exit 0
