#!/bin/bash

UNIFI_VER=$1

if [[ "${UNIFI_VER}" == "" ]]
then
    echo
    echo "    Specify a UniFi controller version! Example:"
    echo "    $ $0 5.12.0"
    echo
    echo "    Find new versions at https://community.ui.com/releases"
    echo
    exit 1
fi

mkdir -p extract/${UNIFI_VER}

wget -O extract/unifi.${UNIFI_VER}.deb https://dl.ui.com/unifi/${UNIFI_VER}/unifi_sysvinit_all.deb

pushd extract/${UNIFI_VER}
    ar -x ../unifi.${UNIFI_VER}.deb
    tar xvf control.tar.gz
    tar xvf data.tar.xz
popd

rm -f unifi.${UNIFI_VER}.deb
