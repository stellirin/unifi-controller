#!/bin/bash

JVM_EXTRA_OPTS=
JVM_MAX_HEAP_SIZE=${JVM_MAX_HEAP_SIZE:-"1024M"}
MONGO_DB_NAME=${MONGO_DB_NAME:-"unifi"}
MONGO_DB_URI=${MONGO_DB_URI:-"mongodb://localhost:27017"}
UNIFI_HTTPS_PORT=${UNIFI_HTTPS_PORT:-"8443"}

# OpenShift requires ability to run as arbitrary user ID
arbitrary_user_id() {
    USER_NAME=unifi
    if ! whoami &> /dev/null; then
        if [ -w /etc/passwd ]; then
            echo "${USER_NAME}:x:$(id -u):0:${USER_NAME} user:${BASEDIR}:/sbin/nologin" >> /etc/passwd
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

    if [ $? -ne 0 ]
    then
        exit 1
    else
        exit 0
    fi
}

arbitrary_user_id

set_system_property "db.mongo.local=false"
set_system_property "db.mongo.uri=${MONGO_DB_URI}"
set_system_property "statdb.mongo.uri=${MONGO_DB_URI}"
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
    kill -0 $PID
    if [ $? -gt 0 ]
    then
        unifi_stop
        sleep 1d
    else
        sleep 1s
    fi
done
