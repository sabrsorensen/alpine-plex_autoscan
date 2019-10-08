# alpine-plex_autoscan
Alpine Linux-based plex_autoscan image.

**Application**

[plex_autoscan](https://github.com/l3uddz/plex_autoscan)


**Description**

plex_autoscan is a utility by l3uddz for intercepting Plex library refresh/scan requests from media managers such as Sonarr and Radarr and converting the requests into a more targeted scan. This both increases the responsiveness of adding new media to your library and alleviates some of the strain in performing a larger library refresh for each new media item.


**Usage**

This is a very basic example that assumes all of your Plex libraries can be located under the same root directory, mounted to /data in the container, and the directory containing Plex's com.plexapp.plugins.library.db is mounted to /plexDb for ease of configuration in plex_autoscan's config.json.
More complicated setups may require additional volume mappings and configuration within the plex_autoscan config.json.

Mounting the Docker API socket file is necessary for the plex_autoscan service to interact with Plex Docker containers.

Please take your Docker volume mount paths into account when configuring your config.json and replace all user variables in the following command defined by <> with the correct values accordingly.

If using the rclone crypt or cache expire/refresh functionality, you will also need to map your rclone.conf into the container and specify the location in plex_autoscan.config

```
docker run -d \
    -p 3468:3468 \
    --name=<container name> \
    -v <path root directory for all media libraries>:/data \
    -v <path for config files>:/config \
    -v <path to Plex database>:/plexDb \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e PUID=<uid for plexautoscan user> \
    -e PGID=<gid for media group with access to your library> \
    sabrsorensen/alpine-plex_autoscan
```
docker-compose.yml for coexisting plex and plex_autoscan containers, note the matching /data volume mappings:
```
    plex:
        image: plexinc/pms-docker:plexpass
        container_name: plex
        ...
        volumes:
            - /opt/plex/config:/config
            - /opt/plex/transcode:/transcode
            - /media/plex-union:/data
        ...

    plexautoscan:
        image: sabrsorensen/alpine-plex_autoscan
        container_name: plexautoscan
        ...
        environment:
            - PGID=<plexGID>
            - PUID=<plexautoscanUID>
        ports:
            - 3468:3468/tcp
        volumes:
            - /opt/plex_autoscan:/config
            - /opt/plex/config/Library/Application Support/Plex Media Server/Plug-in Support/Databases/:/plexDb
            - /media/plex-union:/data
            - /var/run/docker.sock:/var/run/docker.sock
            - /etc/localtime:/etc/localtime:ro
        ...

    sonarr:
        ...
        volumes:
            - /media/plex-union/tv_shows:/data/tv_shows
        ...
```

and the associated config.json entries to match:

```
  "DOCKER_NAME": "plex", # needs to match your Plex container name
  ...
  "PLEX_DATABASE_PATH": "/plexDb/com.plexapp.plugins.library.db",
  ...
  "PLEX_LD_LIBRARY_PATH": "/usr/lib/plexmediaserver/lib", # path from within the Plex container
  ...
  "PLEX_SCANNER": "/usr/lib/plexmediaserver/Plex\\ Media\\ Scanner", # path from within the Plex container
  ...
  "PLEX_SECTION_PATH_MAPPINGS": {
    "1": [
      "/data/tv_shows/" # Map the path from an incoming scan request to the corresponding Plex library
    ]
  },
  ...
  "PLEX_SUPPORT_DIR": "/config/Plex Media Server/", # path from within the Plex container
  ...
  "RCLONE": {
    "BINARY": "/usr/bin/rclone",
    "CONFIG": "/config/rclone/rclone.conf",
    "CRYPT_MAPPINGS": {},
    "RC_CACHE_EXPIRE": {
      "ENABLED": true,
      "FILE_EXISTS_TO_REMOTE_MAPPINGS": {
          "media/tv_shows": [
            "/data/tv_shows/"
            ]
        },
      "RC_URL": "http://172.18.0.1:5572"
    },
    "RC_CACHE_REFRESH": {
      "ENABLED": true,
      "FILE_EXISTS_TO_REMOTE_MAPPINGS": {
          "media/tv_shows": [
            "/data/tv_shows/"
            ]
        },
      "RC_URL": "http://172.18.0.1:5572"
    }
  },
  ...
  "SERVER_FILE_EXIST_PATH_MAPPINGS": {
    "/data/": [ # path from within plex_autoscan container
      "/data/" # path from within Plex container
    ]
  },
  ...
  "SERVER_PATH_MAPPINGS": {
    "/data/tv_shows/": [ # path from within plex_autoscan container
      "/data/tv_shows/", # path from within Sonarr container
      "My Drive/media/tv_shows/" # path on Google Drive
    ]
  },
  ...
  "SERVER_PORT": 3468, # needs to match the port exposed in the plex_autoscan container
  ...
  "SERVER_SCAN_PRIORITIES": {
    "0": [
      "/data/tv_shows/" # path from within the Plex container
    ]
  },
  ...
  "USE_DOCKER": true,
  "USE_SUDO": false
```
Please reference the documentation for plex_autoscan to configure your config.json and replace all user variables in the above command defined by <> with the correct values accordingly.

If you wish to use the Google Drive change monitoring, you'll need to run the token authorization workflow with the following docker exec command, replacing `<containerName>` with your plex_autoscan container's name:

```
docker exec -it <containerName> /usr/bin/python /opt/plex_autoscan/scan.py authorize
```
