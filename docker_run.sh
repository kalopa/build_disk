#!/bin/sh
#
set -ex

MISSION=1.yaml

BASE_DIR=/home/dtynan
BSDISK=$BASE_DIR/bsdisk
MISSION_DIR=/home/dtynan/Dropbox/Robotics/Sailboat/build_disk/missions

API_KEY="a61ab79e-2ed3-40ce-b08e-4b84dea8de41"

curl -s -H "ApiKey:$API_KEY" -o $MISSION_DIR/$MISSION https://kalopa.com/missions/$MISSION
docker run \
	--privileged \
	-v $BSDISK:/bsdisk \
	-v $MISSION_DIR:/missions \
	-e BSDIR=/bsdisk \
	-e MISSION=/missions/$MISSION \
	registry.kalopa.net/build_disk:latest
exit 0
