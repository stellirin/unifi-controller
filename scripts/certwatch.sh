#!/bin/bash

HASH_CHECK=0

# Get hashes of current TLS certificates
sha256sum ${UNIFI_TLS_FULLCHAIN} ${UNIFI_TLS_PRIVKEY} > /tmp/cert.hash

# No need for frequent checks, TLS certificates rarely change
while [[ "${HASH_CHECK}" == "0" ]]
do
    sleep 1d
    sha256sum --check --status /tmp/cert.hash
    HASH_CHECK=$?
done

# We get here because the TLS certificates changed, so trigger a controller restart
java -jar ${BASEDIR}/lib/ace.jar stop
