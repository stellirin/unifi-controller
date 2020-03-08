#!/bin/bash


# Ensure files are written as writable by all users in the root group
umask 002

JVM_EXTRA_OPTS=
JVM_MAX_HEAP_SIZE=${JVM_MAX_HEAP_SIZE:-"1024M"}

# Generate the MongoDB connection URI
if [ -z "${MONGO_DB_URI}" ]
then
    if [ -n "${MONGO_DB_USER}" ] && [ -n "${MONGO_DB_PASS}" ]
    then
        MONGO_DB_URI=mongodb://${MONGO_DB_USER}:${MONGO_DB_PASS}@${MONGO_DB_HOST:-"localhost"}:${MONGO_DB_PORT:-"27017"}
    else
        MONGO_DB_URI=mongodb://${MONGO_DB_HOST:-"localhost"}:${MONGO_DB_PORT:-"27017"}
    fi
fi

MONGO_DB_NAME=${MONGO_DB_NAME:-"unifi"}
MONGO_DB_STAT_URI=${MONGO_DB_STAT_URI:-"${MONGO_DB_URI}"}
UNIFI_HTTPS_PORT=${UNIFI_HTTPS_PORT:-"8443"}

# Configure TLS
set_tls_keystore() {
    if [ -n "${UNIFI_TLS_FULLCHAIN}" ] && [ -n "${UNIFI_TLS_PRIVKEY}" ]
    then
        if [ -f "${UNIFI_TLS_FULLCHAIN}" ] && [ -f "${UNIFI_TLS_PRIVKEY}" ]
        then

            if [ -f "/var/lib/unifi/keystore" ]
            then
                echo "INFO: Creating backup TLS keystore ..."
                mv /var/lib/unifi/keystore /var/lib/unifi/keystore.backup
            fi

            echo "INFO: Creating intermediate TLS keystore ..."
            openssl pkcs12 \
                -export \
                -in ${UNIFI_TLS_FULLCHAIN} \
                -inkey ${UNIFI_TLS_PRIVKEY} \
                -out /tmp/keystore.p12 \
                -name ubnt \
                -password pass:unifi

            if [ -f "/tmp/keystore.p12" ]
            then
                echo "INFO: Creating final keystore ..."
                keytool \
                    -noprompt \
                    -importkeystore \
                    -srckeystore /tmp/keystore.p12 \
                    -srcstoretype PKCS12 \
                    -srcstorepass unifi \
                    -destkeystore /var/lib/unifi/keystore \
                    -deststorepass aircontrolenterprise \
                    -destkeypass aircontrolenterprise \
                    -alias ubnt
            else
                echo "ERROR: Intermediate TLS keystore not created!"
                if [ -f "/var/lib/unifi/keystore.backup" ]
                then
                    echo "INFO: Restoring backup TLS keystore"
                    mv /var/lib/unifi/keystore.backup /var/lib/unifi/keystore
                fi
                exit 1
            fi

            if [ -f "/var/lib/unifi/keystore" ]
            then
                echo "INFO: Final TLS keystore created"
                rm -f /tmp/fullchain.p12
                if [ -f "/var/lib/unifi/keystore.backup" ]
                then
                    echo "INFO: Removing backup TLS keystore"
                    rm -f /var/lib/unifi/keystore.backup
                fi

                # Certificates installed, watch for changes
                /certwatch.sh &
            else
                echo "ERROR: Final TLS keystore not created!"
                rm -f /tmp/fullchain.p12
                if [ -f "/var/lib/unifi/keystore.backup" ]
                then
                    echo "INFO: Restoring backup TLS keystore"
                    mv /var/lib/unifi/keystore.backup /var/lib/unifi/keystore
                fi
                exit 1
            fi
        else
            echo "ERROR: Path to certificates supplied but file(s) not found!"
            exit 1
        fi
    fi
}

# Set up the UniFi system properties
set_system_property() {
    property=$(echo $1 | cut -d '=' -f 1)
    value=$(echo $1 | cut -d '=' -f 2-)

    # Initialize property file on first start
    property_file="${DATADIR}/system.properties"
    touch ${property_file}

    # Test if value is empty
    if [ -z "${value}" ]
    then
        # Fully remove empty property
        sed -i -r "s|^${property}.*$||g" ${property_file}
    else
        # Test if property is already set
        if grep -q ^"${property}" "${property_file}"
        then
            # Replace value of existing property
            sed -i -r "s|^${property}.*$|${property}=${value}|g" ${property_file}
        else
            # Append new property
            echo "${property}=${value}" >>  ${property_file}
        fi
    fi
}

# Set up the UniFi JVM options
set_jvm_extra_opts() {
    option=$(echo $1 | cut -d '=' -f 1)
    value=$(echo $1 | cut -d '=' -f 2-)

    JVM_EXTRA_OPTS="${JVM_EXTRA_OPTS} -D${option}=${value}"
}

# Start UniFi
unifi_start() {
    JVM_OPTS="${JVM_EXTRA_OPTS} -Xmx${JVM_MAX_HEAP_SIZE} ${UNIFI_JVM_EXTRA_OPTS}"
    java ${JVM_OPTS} -jar ${BASEDIR}/lib/ace.jar start &

    # Return code is UniFi PID
    return $!
}

# Stop UniFi
unifi_stop() {
    JVM_OPTS="${JVM_EXTRA_OPTS} -Xmx${JVM_MAX_HEAP_SIZE} ${UNIFI_JVM_EXTRA_OPTS}"
    java ${JVM_OPTS} -jar ${BASEDIR}/lib/ace.jar stop

    # Container exit code is UniFi exit code
    exit $?
}

set_tls_keystore

set_system_property "db.mongo.local=false"
set_system_property "db.mongo.uri=${MONGO_DB_URI}"
set_system_property "statdb.mongo.uri=${MONGO_DB_STAT_URI}"
set_system_property "unifi.db.name=${MONGO_DB_NAME}"
set_system_property "unifi.https.port=${UNIFI_HTTPS_PORT}"

set_jvm_extra_opts "file.encoding=UTF-8"
set_jvm_extra_opts "java.awt.headless=true"
[ -n "${JAVA_ENTROPY_GATHER_DEVICE}" ] && set_jvm_extra_opts "java.security.egd=${JAVA_ENTROPY_GATHER_DEVICE}"
set_jvm_extra_opts "log4j.configurationFile=file:${BASEDIR}/log4j2.xml"
set_jvm_extra_opts "unifi.datadir=${DATADIR}"
set_jvm_extra_opts "unifi.logdir=${LOGDIR}"
set_jvm_extra_opts "unifi.rundir=${RUNDIR}"

unifi_start
PID=$?

# Try to perform a graceful shutdown
trap unifi_stop INT KILL TERM

# Keep PID 1 alive until UniFi exits
while true
do
    # This doesn't actually kill the process, it just tests if $PID is something that could be killed (i.e. the process exists)
    kill -0 $PID
    if [ $? -gt 0 ]
    then
        unifi_stop
    else
        sleep 1
    fi
done
