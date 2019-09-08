# Extract UniFi DEB

```
UNIFI_VER=5.11.39
wget -O unifi.${UNIFI_VER}.deb https://dl.ui.com/unifi/${UNIFI_VER}/unifi_sysvinit_all.deb
mkdir ${UNIFI_VER}
pushd ${UNIFI_VER}
ar x ../unifi.${UNIFI_VER}.deb
tar xf control.tar.gz
tar xf data.tar.xz
popd

```
