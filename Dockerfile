FROM alpine:latest
MAINTAINER sabrsorensen@gmail.com

# install plex_autoscan dependencies and curl and grep for helper script dependencies.
RUN apk -U add docker gcc git python2-dev py2-pip musl-dev linux-headers curl grep

# download plex_autoscan
RUN git clone --depth 1 --single-branch --branch master https://github.com/l3uddz/plex_autoscan /plex_autoscan && \
    # install pip requirements
    cd /plex_autoscan && \
    python -m pip install --no-cache-dir -r requirements.txt && \
    # link the config directory to expose as a volume
    ln -s /plex_autoscan/config /config

ADD start-plex_autoscan.sh /
RUN chmod +x /start-plex_autoscan.sh

ADD healthcheck-plex_autoscan.sh /
RUN chmod +x /healthcheck-plex_autoscan.sh

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# expose port for http
EXPOSE 3468/tcp

CMD ["/bin/sh", "/start-plex_autoscan.sh"]

HEALTHCHECK --interval=20s --timeout=10s --start-period=10s --retries=5 \
    CMD ["/bin/sh", "/healthcheck-plex_autoscan.sh"]
