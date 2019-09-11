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
Please reference the documentation for plex_autoscan to configure your config.json and replace all user variables in the above command defined by <> with the correct values accordingly.

If you wish to use the Google Drive change monitoring, you'll need to run the token authorization workflow with the following docker exec command, replacing `<containerName>` with your plex_autoscan container's name:

```
docker exec -it <containerName> /usr/bin/python /opt/plex_autoscan/scan.py authorize
```


**Notes**

User ID (PUID) and Group ID (PGID) can be found by issuing the following command for the user you want to run the container as:-

```
id <username>
```

