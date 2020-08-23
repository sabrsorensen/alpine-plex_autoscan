FROM alpine:latest
ARG OVERLAY_ARCH="amd64"
ARG OVERLAY_VERSION="v2.0.0.1"
ARG BUILD_DATE="unknown"
ARG COMMIT_AUTHOR="unknown"

LABEL maintainer=${COMMIT_AUTHOR} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.build-date=${BUILD_DATE}
RUN \
 echo "**** install build packages ****" && \
 echo http://dl-cdn.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories && \
 apk --no-cache update -qq && apk --no-cache upgrade -qq && apk --no-cache fix -qq && \
 apk add --quiet --no-cache \
        docker \
        gcc \
        git \
        python3 \
        python3-dev \
        py3-pip \
        musl-dev \
        linux-headers \
        curl \
        grep \
        shadow \
        tzdata \
        openssl \
        ca-certificates \
        fuse \
        unzip \
        wget \
        bash && \
  echo "**** ${OVERLAY_VERSION} used ****" && \
  curl -o /tmp/s6-overlay.tar.gz -L "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" >/dev/null 2>&1 && \
  tar xfz /tmp/s6-overlay.tar.gz -C / >/dev/null 2>&1 && rm -rf /tmp/s6-overlay.tar.gz >/dev/null 2>&1 && \
  rm -rf /var/cache/apk/APK**

RUN \
 echo "**** install plex_autoscan ****" && \
 git clone --depth 1 --single-branch https://github.com/l3uddz/plex_autoscan.git /opt/plex_autoscan
RUN \
   echo "**** install rclone ****" && \
   wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip >/dev/null 2>&1 && \
   unzip -qq rclone.zip && rm rclone.zip && \
   mv rclone*/rclone /usr/bin && rm -rf rclone*

ENV PATH=/opt/plex_autoscan:${PATH}
COPY scan /opt/plex_autoscan

# install pip requirements
RUN python3 -m pip install --no-cache-dir -r /opt/plex_autoscan/requirements.txt && \
    ln -s /opt/plex_autoscan/config /config
# environment variables to keep the init script clean
ENV DOCKER_CONFIG=/home/plexautoscan/docker_config.json PLEX_AUTOSCAN_CONFIG=/config/config.json PLEX_AUTOSCAN_LOGFILE=/config/plex_autoscan.log PLEX_AUTOSCAN_LOGLEVEL=INFO PLEX_AUTOSCAN_QUEUEFILE=/config/queue.db PLEX_AUTOSCAN_CACHEFILE=/config/cache.db
ADD root/ /
VOLUME /config
VOLUME /plexDb
COPY healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/bash", "/healthcheck-plex_autoscan.sh"]
# expose port for http
EXPOSE 3468/tcp
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/init"]
