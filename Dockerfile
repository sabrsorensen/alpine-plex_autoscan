FROM rclone/rclone
MAINTAINER sabrsorensen@gmail.com

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/sabrsorensen/alpine-plex_autoscan.git" \
      org.label-schema.build-date=$BUILD_DATE

# linking the base image's rclone binary to the path expected by plex_autoscan's default config
RUN ln /root/rclone /usr/bin/rclone

# install plex_autoscan dependencies and curl and grep for helper script dependencies.
RUN apk -U add docker gcc git python2-dev py2-pip musl-dev linux-headers curl grep

ENV PLEX_AUTOSCAN_CONFIG /config/config.json
ENV PLEX_AUTOSCAN_LOGFILE /config/plex_autoscan.log
ENV PLEX_AUTOSCAN_LOGLEVEL INFO
ENV PLEX_AUTOSCAN_QUEUEFILE /config/queue.db
ENV PLEX_AUTOSCAN_CACHEFILE /config/cache.db

# download plex_autoscan
RUN git clone --depth 1 --single-branch --branch master https://github.com/l3uddz/plex_autoscan /opt/plex_autoscan && \
    # install pip requirements
    cd /opt/plex_autoscan && \
    python -m pip install --no-cache-dir -r requirements.txt && \
    # link the config directory to expose as a volume
    ln -s /opt/plex_autoscan/config /config

ADD start-plex_autoscan.sh /
RUN chmod +x /start-plex_autoscan.sh

ADD healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# expose port for http
EXPOSE 3468/tcp

ENTRYPOINT ["/bin/sh", "/start-plex_autoscan.sh"]

HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]
