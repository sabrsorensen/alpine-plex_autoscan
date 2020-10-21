#! /bin/sh

if [ ! -f ${PLEX_AUTOSCAN_CONFIG} ]
then
    python3 /opt/plex_autoscan/scan.py sections
    echo "Default config.json generated, please configure for your environment. Exiting."
else
    server_ip=$(grep "SERVER_IP" ${PLEX_AUTOSCAN_CONFIG} | awk -F '"' '{print $4}')
    if [ $server_ip = "0.0.0.0" ]
    then
        server_ip="127.0.0.1"
    fi

    server_port=$(grep "SERVER_PORT" ${PLEX_AUTOSCAN_CONFIG} | awk -F ': ' '{print $2}' | awk -F ',' '{print $1}')
    server_pass=$(grep "SERVER_PASS" ${PLEX_AUTOSCAN_CONFIG} | awk -F '"' '{print $4}')
    plex_autoscan_url="http://${server_ip}:${server_port}/${server_pass}"
    plex_autoscan_test_result=$(curl -LIs -f ${plex_autoscan_url} -o /dev/null -w '%{http_code}\n')
    if [ ${plex_autoscan_test_result} = 200 ]
    then
        echo "plex_autoscan is healthy."
    else
        echo "WARNING: plex_autoscan is unhealthy: status code $plex_autoscan_test_result"
        exit 1
    fi

    plex_url=$(grep "PLEX_LOCAL_URL" ${PLEX_AUTOSCAN_CONFIG} | awk -F\" '{print $4}')
    plex_token=$(grep "PLEX_TOKEN" ${PLEX_AUTOSCAN_CONFIG} | awk -F\" '{print $4}')
    plex_test_url="${plex_url}/?X-Plex-Token=${plex_token}"
    plex_test_result=$(curl -LIs "${plex_test_url}" -o /dev/null -w '%{http_code}\n')
    if [ ${plex_test_result} = 200 ]
    then
        echo "Plex is healthy."
        exit 0
    else
        echo "WARNING: Plex unavailable at configured PLEX_LOCAL_URL or PLEX_TOKEN is incorrect."
        exit 1
    fi
fi
