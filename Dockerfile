FROM rclone/rclone
MAINTAINER sabrsorensen@gmail.com

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/sabrsorensen/alpine-plex_autoscan.git" \
      org.label-schema.build-date=$BUILD_DATE

# linking the base image's rclone binary to the path expected by plex_autoscan's default config
RUN ln /usr/local/bin/rclone /usr/bin/rclone

# install plex_autoscan dependencies, shadow for user management, and curl and grep for healthcheck script dependencies.
RUN apk -U --no-cache add \
        docker \
        gcc \
        git \
        python2-dev \
        py2-pip \
        musl-dev \
        linux-headers \
        curl \
        grep \
        shadow \
        tzdata

# install s6-overlay for process management
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /
ENTRYPOINT ["/init"]

# download plex_autoscan
RUN git clone --depth 1 --single-branch --branch master https://github.com/l3uddz/plex_autoscan /opt/plex_autoscan
WORKDIR /opt/plex_autoscan
# install pip requirements
RUN python -m pip install --no-cache-dir -r requirements.txt && \
    # link the config directory to expose as a volume
    ln -s /opt/plex_autoscan/config /config

# environment variables to keep the init script clean
ENV DOCKER_CONFIG /home/plexautoscan/docker_config.json
ENV PLEX_AUTOSCAN_CONFIG /config/config.json
ENV PLEX_AUTOSCAN_LOGFILE /config/plex_autoscan.log
ENV PLEX_AUTOSCAN_LOGLEVEL INFO
ENV PLEX_AUTOSCAN_QUEUEFILE /config/queue.db
ENV PLEX_AUTOSCAN_CACHEFILE /config/cache.db

# add s6-overlay scripts and config
ADD root/ /

# create plexautoscan user
RUN useradd -U -r -m -G docker -s /bin/false plexautoscan

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /plexDb to directory containing the Plex library database.
VOLUME /plexDb

# add healthcheck to scrape the manual scan page
ADD healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]

# expose port for http
EXPOSE 3468/tcp
