#
# UniFi Network Controller
#
FROM ibm-semeru-runtimes:open-8-jre-focal

ARG UNIFI_VER=7.0.25
ARG UNIFI_URL=https://dl.ui.com/unifi/${UNIFI_VER}/unifi_sysvinit_all.deb
ARG UNIFI_USER=10017

# Set the product installation directory
ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/var/lib/unifi \
    LOGDIR=/var/log/unifi \
    RUNDIR=/var/run/unifi

RUN curl -L -o /unifi.deb ${UNIFI_URL} \
    && dpkg --unpack /unifi.deb \
    && rm -rf /unifi.deb

# usr/lib/unifi/lib/ace.jar
# sudo apt-get install binutils xz-utils
# PROTIP: unzip -p usr/lib/unifi/lib/ace.jar log4j2.xml > /workspace/log4j2.new.xml
COPY log4j2.xml /usr/lib/unifi/

COPY scripts/*.sh /

# https://github.com/moby/moby/issues/38710
# Set permissions on folders, add default user to /etc/passwd
RUN echo "unifi:x:${UNIFI_USER}:0:unifi:${BASEDIR}:/sbin/nologin" >> /etc/passwd \
    && mkdir -p ${DATADIR} \
    && chmod g=u ${DATADIR} \
    && ln -s ${DATADIR} ${BASEDIR}/data \
    && mkdir -p ${LOGDIR} \
    && chmod g=u ${LOGDIR} \
    && ln -s ${LOGDIR} ${BASEDIR}/logs \
    && mkdir -p ${RUNDIR} \
    && chmod g=u ${RUNDIR} \
    && ln -s ${RUNDIR} ${BASEDIR}/run

# 1900:  Controller discovery
# 3478:  STUN
# 6789:  Speed test
# 8080:  Device <> controller communication
# 8443:  Controller GUI/API as seen in a web browser
# 8880:  HTTP portal redirection
# 8843:  HTTPS portal redirection
# 10001: AP discovery
EXPOSE 1900/udp
EXPOSE 3478/udp
EXPOSE 6789/tcp
EXPOSE 8080/tcp
EXPOSE 8443/tcp
EXPOSE 8880/tcp
EXPOSE 8843/tcp
EXPOSE 10001/udp

HEALTHCHECK --start-period=2m --interval=1m --timeout=15s --retries=3 \
    CMD ["/healthcheck.sh"]

# Containers should NOT run as root
USER ${UNIFI_USER}:0
WORKDIR ${BASEDIR}
VOLUME ${DATADIR}
ENTRYPOINT ["/entrypoint.sh"]
