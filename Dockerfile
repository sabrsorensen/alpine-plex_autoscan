FROM alpine:latest
MAINTAINER sabrsorensen@gmail.com

RUN apk -U add docker gcc git python2-dev py2-pip musl-dev linux-headers

# download plex_autoscan
RUN git clone --depth 1 --single-branch --branch master https://github.com/l3uddz/plex_autoscan /plex_autoscan && \
    # install pip requirements
    cd /plex_autoscan && \
    python -m pip install --no-cache-dir -r requirements.txt && \
    # link the config directory to expose as a volume
    ln -s /plex_autoscan/config /config

ADD start-plex_autoscan.sh /

RUN chmod +x /start-plex_autoscan.sh

# map /config to host defined config path (used to store configuration from app)
VOLUME /config

# expose port for http
EXPOSE 3468/tcp

# set permissions
#################

# run script to set uid, gid and permissions
CMD ["/bin/sh", "/start-plex_autoscan.sh"]
