#! /bin/sh

if [ ! -f ${PLEX_AUTOSCAN_CONFIG} ]
then
    python3 /opt/plex_autoscan/scan.py sections
    echo "Default config.json generated, please configure for your environment. Exiting."
else
    server_ip=$(grep SERVER_IP ${PLEX_AUTOSCAN_CONFIG} | awk -F '"' '{print $4}')
    if [ $server_ip = "0.0.0.0" ]
    then
        server_ip="127.0.0.1"
    fi
    server_port=$(grep SERVER_PORT ${PLEX_AUTOSCAN_CONFIG} | awk -F ': ' '{print $2}' | awk -F ',' '{print $1}')
    server_pass=$(grep SERVER_PASS ${PLEX_AUTOSCAN_CONFIG} | awk -F '"' '{print $4}')
    url="http://${server_ip}:${server_port}/${server_pass}"
    curl --silent --show-error -f $url > /dev/null || exit 1
    PAGE=$(cat ${PLEX_AUTOSCAN_CONFIG} | grep '"PLEX_LOCAL_URL":' | awk -F\" '{print $4}')
    TOKEN=$(cat ${PLEX_AUTOSCAN_CONFIG} | grep '"PLEX_TOKEN":' | awk -F: '{print $2}' | awk -F\" '{print $2}')
    PGSELFTEST=$(curl -LI "${PAGE}/system?X-Plex-Token=${TOKEN}" -o /dev/null -w '%{http_code}\n' -s)
    ######## FUNCTIONS ##########
    if [ -f ${PLEX_AUTOSCAN_CONFIG} ]
       then
       if [[ -f ${PLEX_AUTOSCAN_CONFIG} && ${PGSELFTEST} -le 200 && ${PGSELFTEST} -gt 299 ]]
          then
          echo "[ WARNING ] -> PLEX_AUTOSCAN_CONFIG missing <- [ WARNING ]"
          echo "[ WARNING ] -> PLEX down or Token missmatched [ WARNING ]"
          echo "[ WARNING ] -> next check for accesible in 5 seconds [ WARNING ]"
          sleep 5
          if [[ ${PGSELFTEST} -le 200 && ${PGSELFTEST} -gt 299 ]]; then
            echo "[ WARNING ] second check also failed [WARNING ]"
            echo " exit now "
            exit 1
          fi
	    else
          echo " Config and Plex works and Token matched "
       fi
    else
       echo " [ WARNING ] PLEX Down or Token missmatched [ WARNING ] "
    fi
fi
