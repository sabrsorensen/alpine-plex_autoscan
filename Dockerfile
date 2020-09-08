FROM alpine:latest
ARG BUILD_DATE="unknown"
ARG COMMIT_AUTHOR="unknown"

LABEL maintainer=${COMMIT_AUTHOR} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.build-date=${BUILD_DATE}

RUN \
 echo "**** install build packages ****" && \
  echo http://dl-cdn.alpinelinux.org/alpine/edge/community/ >> /etc/apk/repositories && \
 apk --quiet --no-cache --no-progress add \
       docker gcc git python3 python3-dev py3-pip musl-dev \
        linux-headers curl grep shadow tzdata wget bash tar rclone && \
        rm -rf /var/cache/apk/*

RUN \
  echo "**** Install s6-overlay ****" && \ 
  curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]' > /etc/S6_RELEASE && \
  wget https://github.com/just-containers/s6-overlay/releases/download/`cat /etc/S6_RELEASE`/s6-overlay-amd64.tar.gz -O /tmp/s6-overlay-amd64.tar.gz >/dev/null 2>&1 && \
  tar xzf /tmp/s6-overlay-amd64.tar.gz -C / >/dev/null 2>&1 && \
  rm /tmp/s6-overlay-amd64.tar.gz >/dev/null 2>&1 && \
  echo "**** Installed s6-overlay `cat /etc/S6_RELEASE` ****"

RUN \
  echo "**** update pip ****" && \
  pip -q install --upgrade pip idna==2.8

RUN \
  echo "**** install plex_autoscan ****" && \
  git clone --depth 1 --single-branch --branch develop https://github.com/doob187/plex_autoscan /opt/plex_autoscan

ENV PATH=/opt/plex_autoscan:${PATH}
COPY scan /opt/plex_autoscan

# install pip requirements
RUN \
    echo "**** install requirements ****" && \
    python3 -m pip -q install --no-cache-dir -r /opt/plex_autoscan/requirements.txt && \
    ln -s /opt/plex_autoscan/config /config

# environment variables to keep the init script clean
ENV DOCKER_CONFIG=/home/plexautoscan/docker_config.json PLEX_AUTOSCAN_CONFIG=/config/config.json PLEX_AUTOSCAN_LOGFILE=/config/plex_autoscan.log PLEX_AUTOSCAN_LOGLEVEL=INFO PLEX_AUTOSCAN_QUEUEFILE=/config/queue.db PLEX_AUTOSCAN_CACHEFILE=/config/cache.db

## VOLUMEN & ROOT
ADD root/ /
VOLUME /config
VOLUME /plexDb
## healtcheck
COPY healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/bash", "/healthcheck-plex_autoscan.sh"]
# expose port for http
EXPOSE 3468/tcp
ENTRYPOINT ["/bin/bash", "-c"]
CMD ["/init"]
