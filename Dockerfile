FROM rclone/rclone

ARG BUILD_DATE="unknown"
ARG COMMIT_AUTHOR="unknown"
ARG VCS_REF="unknown"
ARG VCS_URL="unknown"
ARG ARCH="amd64"

LABEL maintainer=${COMMIT_AUTHOR} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.build-date=${BUILD_DATE}

# linking the base image's rclone binary to the path expected by plex_autoscan's default config
RUN ln /usr/local/bin/rclone /usr/bin/rclone

# install plex_autoscan dependencies (python3, py3-setuptools to run; py3-pip to keep pip dependencies installed; docker-cli to talk to docker; git to check for latest version), shadow for user management, and curl and grep for healthcheck script dependencies.
RUN apk -U --no-cache add \
    docker-cli \
    git \
    python3 \
    py3-setuptools \
    py3-pip \
    curl \
    grep \
    shadow && \
    pip install --upgrade pip idna==2.8

# download plex_autoscan
RUN git clone --depth 1 --single-branch --branch develop https://github.com/l3uddz/plex_autoscan /opt/plex_autoscan

# add s6-overlay scripts and config, copy plex_autoscan wrapper for 'easy docker run' usage.
ADD root/ /

# install s6-overlay for process management
RUN /tmp/get_s6-overlay.sh && rm /tmp/get_s6-overlay.sh

WORKDIR /opt/plex_autoscan
# install pip requirements and related build dependencies, remove build deps when no longer needed
RUN apk -U --no-cache --virtual .build-deps add \
    gcc \
    linux-headers \
    musl-dev \
    python3-dev && \
    python3 -m pip install --no-cache-dir -r requirements.txt && \
    apk -U --no-cache del .build-deps && \
    # link the config directory to expose as a volume
    ln -s /opt/plex_autoscan/config /config

# environment variables to keep the init script clean
ENV DOCKER_CONFIG=/home/plexautoscan/docker_config.json \
    PLEX_AUTOSCAN_CONFIG=/config/config.json \
    PLEX_AUTOSCAN_LOGFILE=/config/plex_autoscan.log \
    PLEX_AUTOSCAN_LOGLEVEL=INFO \
    PLEX_AUTOSCAN_QUEUEFILE=/config/queue.db \
    PLEX_AUTOSCAN_CACHEFILE=/config/cache.db \
    PATH=/opt/plex_autoscan:${PATH}

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /plexDb to directory containing the Plex library database.
VOLUME /plexDb

# add healthcheck to scrape the manual scan page
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]

# expose port for http
EXPOSE 3468/tcp

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/init"]