#
# UniFi Network Controller
#
FROM adoptopenjdk:8-jre-openj9

ARG UNIFI_VER=5.12.19-98bbc5381e
ARG UNIFI_URL=https://dl.ui.com/unifi/${UNIFI_VER}/unifi_sysvinit_all.deb

# Set the product installation directory
ENV BASEDIR=/usr/lib/unifi \
    DATADIR=/var/lib/unifi \
    LOGDIR=/var/log/unifi \
    RUNDIR=/var/run/unifi

RUN curl -L -o /unifi.deb ${UNIFI_URL} \
 && dpkg -x /unifi.deb / \
 && rm -rf /unifi.deb

COPY log4j2.xml /usr/lib/unifi/

COPY scripts/*.sh /

# https://github.com/moby/moby/issues/38710
# Set permissions on folders and /etc/passwd
RUN chmod g=u /etc/passwd \
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
USER 999
WORKDIR ${BASEDIR}
VOLUME ${DATADIR}
ENTRYPOINT ["/entrypoint.sh"]
