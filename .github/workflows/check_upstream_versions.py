#! /usr/bin/python

###############################################################################
# Query for the latest versions of s6-overlay, rclone, and plex_autoscan
###############################################################################
import argparse
import json
import os
import requests
import sys

if os.path.exists('upstream_versions'):
    try:
        with open('upstream_versions', 'r') as ver_file:
            old_versions = json.load(ver_file)
            print("Previously detected versions: \n" +
                  json.dumps(old_versions, indent=2))
    except:
        os.remove('upstream_versions')
        print("Invalid upstream_versions. Removing and starting fresh.")

current_versions = {}
current_versions['s6_overlay_release_name'] = requests.get(
    'https://api.github.com/repos/just-containers/s6-overlay/releases/latest').json()["tag_name"]
current_versions['rclone_release_name'] = requests.get(
    'https://api.github.com/repos/rclone/rclone/releases/latest').json()["tag_name"]
current_versions['plex_autoscan_commit_ref'] = requests.get(
    'https://api.github.com/repos/l3uddz/plex_autoscan/commits/develop').json()["sha"]

print("Current detected versions: \n" + json.dumps(current_versions, indent=2))
with open('upstream_versions', 'w') as ver_file:
    json.dump(current_versions, ver_file)

if old_versions == current_versions:
    print("No version change, skipping image rebuild.")
    sys.exit(0)
else:
    print("Upstream versions changed, triggering image rebuild by exiting with error code 1.")
    sys.exit(1)
