#! /bin/sh

cd /plex_autoscan
git pull

if [ ! -f /config/config.json ]
then
    python /plex_autoscan/scan.py sections --config=/config/config.json --loglevel=INFO --cachefile=/config/cache.db --queuefile=/config/queue.db --logfile=/config/plex_autoscan.log
    echo "Default config.json generated, please configure for your environment. Exiting."
elif grep -q '"PLEX_TOKEN": "",' /config/config.json
then
    echo "config.json has not been configured, exiting."
else
    python /plex_autoscan/scan.py server --config=/config/config.json --loglevel=INFO --cachefile=/config/cache.db --queuefile=/config/queue.db --logfile=/config/plex_autoscan.log
fi

