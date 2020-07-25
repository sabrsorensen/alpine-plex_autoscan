FROM rclone/rclone

ARG BUILD_DATE="unknown"
ARG COMMIT_AUTHOR="unknown"
ARG VCS_REF="unknown"
ARG VCS_URL="unknown"

LABEL maintainer=${COMMIT_AUTHOR} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.build-date=${BUILD_DATE}


# linking the base image's rclone binary to the path expected by plex_autoscan's default config
RUN ln /usr/local/bin/rclone /usr/bin/rclone

# install plex_autoscan dependencies, shadow for user management, and curl and grep for healthcheck script dependencies.
RUN apk -U --no-cache add \
        docker \
        gcc \
        git \
        python3 \
        python3-dev \
        py3-pip \
        musl-dev \
        linux-headers \
        curl \
        grep \FROM rclone/rclone

ARG BUILD_DATE="unknown"
ARG COMMIT_AUTHOR="unknown"
ARG VCS_REF="unknown"
ARG VCS_URL="unknown"

LABEL maintainer=${COMMIT_AUTHOR} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.build-date=${BUILD_DATE}


# linking the base image's rclone binary to the path expected by plex_autoscan's default config
RUN ln /usr/local/bin/rclone /usr/bin/rclone

# install plex_autoscan dependencies, shadow for user management, and curl and grep for healthcheck script dependencies.
RUN apk -U --no-cache add \
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
        tzdata

# install s6-overlay for process management
ADD https://github.com/just-containers/s6-overlay/releases/download/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/
RUN tar xzf /tmp/s6-overlay-amd64.tar.gz -C /

# download plex_autoscan
RUN git clone --depth 1 --single-branch https://github.com/l3uddz/plex_autoscan /opt/plex_autoscan
WORKDIR /opt/plex_autoscan

# copy wrapper for 'easy docker run' usage.
ENV PATH=/opt/plex_autoscan:${PATH}
COPY scan /opt/plex_autoscan

# install pip requirements
RUN python3 -m pip install --no-cache-dir -r requirements.txt && \
    # link the config directory to expose as a volume
    ln -s /opt/plex_autoscan/config /config

# environment variables to keep the init script clean
ENV DOCKER_CONFIG=/home/plexautoscan/docker_config.json PLEX_AUTOSCAN_CONFIG=/config/config.json PLEX_AUTOSCAN_LOGFILE=/config/plex_autoscan.log PLEX_AUTOSCAN_LOGLEVEL=INFO PLEX_AUTOSCAN_QUEUEFILE=/config/queue.db PLEX_AUTOSCAN_CACHEFILE=/config/cache.db

# add s6-overlay scripts and config
ADD root/ /

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /rclone_config to host defined rclone config path (used to store rclone configuration files)
VOLUME /rclone_config

# map /plexDb to directory containing the Plex library database.
VOLUME /plexDb

# add healthcheck to scrape the manual scan page
COPY healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]


# expose port for http
EXPOSE 3468/tcp

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/init"]
        shadow \
        tzdata

## InstalL s6 overlay latest version
RUN S6_RELEASE=$(curl -sX GET "https://api.github.com/repos/just-containers/s6-overlay/releases/latest" | awk '/tag_name/{print $4;exit}' FS='[""]'); \
    wget https://github.com/just-containers/s6-overlay/releases/download/${S6_RELEASE}/s6-overlay-amd64.tar.gz -O s6-overlay.tar.gz && \
    tar xfv s6-overlay.tar.gz -C / && \
    rm -r s6-overlay.tar.gz
RUN apk update -qq && apk upgrade -qq && apk fix -qq
ENTRYPOINT ["/init"]

RUN wget https://downloads.rclone.org/rclone-current-linux-amd64.zip -O rclone.zip --no-check-certificate && \
    unzip rclone.zip && rm rclone.zip && \
    mv rclone*/rclone /usr/bin && rm -r rclone* && \
    mkdir -p /rclone

# download plex_autoscan
RUN git clone --depth 1 --single-branch https://github.com/l3uddz/plex_autoscan /opt/plex_autoscan
WORKDIR /opt/plex_autoscan

# copy wrapper for 'easy docker run' usage.
ENV PATH=/opt/plex_autoscan:${PATH}
COPY scan /opt/plex_autoscan

# install pip requirements
RUN python3 -m pip install --no-cache-dir -r requirements.txt && \
    # link the config directory to expose as a volume
    ln -s /opt/plex_autoscan/config /config

# environment variables to keep the init script clean
ENV DOCKER_CONFIG=/home/plexautoscan/docker_config.json PLEX_AUTOSCAN_CONFIG=/config/config.json PLEX_AUTOSCAN_LOGFILE=/config/plex_autoscan.log PLEX_AUTOSCAN_LOGLEVEL=INFO PLEX_AUTOSCAN_QUEUEFILE=/config/queue.db PLEX_AUTOSCAN_CACHEFILE=/config/cache.db

# add s6-overlay scripts and config
ADD root/ /

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /rclone_config to host defined rclone config path (used to store rclone configuration files)
VOLUME /rclone_config

# map /plexDb to directory containing the Plex library database.
VOLUME /plexDb

# add healthcheck to scrape the manual scan page
COPY healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]


# expose port for http
EXPOSE 3468/tcp


ENTRYPOINT ["/bin/sh", "-c"]
FROM rclone/rclone

ARG BUILD_DATE="unknown"
ARG COMMIT_AUTHOR="unknown"
ARG VCS_REF="unknown"
ARG VCS_URL="unknown"

LABEL maintainer=${COMMIT_AUTHOR} \
    org.label-schema.vcs-ref=${VCS_REF} \
    org.label-schema.vcs-url=${VCS_URL} \
    org.label-schema.build-date=${BUILD_DATE}


# linking the base image's rclone binary to the path expected by plex_autoscan's default config
RUN ln /usr/local/bin/rclone /usr/bin/rclone

# install plex_autoscan dependencies, shadow for user management, and curl and grep for healthcheck script dependencies.
RUN apk -U --no-cache add \
        docker \
        gcc \
        git \
        python3 \
        python3-dev \
        py3-pip \
        sl-dev \
        linux-headers \
        curl \
        grep \
        shadow \
        

# install s6-overlay for process management
ADD https://github.com/just-containers/s6-overlay/releases/domrwnload/v1.22.1.0/s6-overlay-amd64.tar.gz /tmp/

# download plex_autoscan
RUN git clone --depth 1 --single-branch https://github.com/l3uddz/plex_autoscan /opt/plex_autoscan
WORKDIR /opt/plex
# copy wrapper for 'easy docker run' usage.

COPY scan /opt/plex_autoscan

# install pip requirements
RUN python3 -m pip install --no-cache-dir -r requirements.txt && \
    # link the config directory to expose as a volume
    ln -s /opt/plex_autoscan/config /config

# environment variables to keep the init script clean
ENV DOCKER_CONFIG=/home/plexautoscan/docker_config.json PLEX_AUTOSCAN_CONFIG=/config/config.json PLEX_AUTOSCAN_LOGFILE=/config/plex_autoscan.log PLEX_AUTOSCAN_LOGLEVEL=INFO PLEX_AUTOSCAN_QUEUEFILE=/config/queue.db PLEX_AUTOSCAN_CACHEFILE=/config/cache.db

# add s6-overlay scripts and config
ADD root/ /

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# map /rclone_config to host defined rclone config path (used to store rclone configuration files)
VOLUME /rclone_config

# map /plexDb to directory containing the Plex library database.
VOLUME /plexDb

# add healthcheck to scrape the manual scan page
COPY healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh
HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]


# expose port for http
EXPOSE 3468/tcp

ENTRYPOINT ["/bin/sh", "-c"]
CMD ["/init"]
