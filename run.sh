#!/bin/sh
set -e

mkdir -p $HOME/bsdisk
docker run -it \
	-v $HOME/bsdisk:/disk \
	-e BSDIR=/disk \
	kalopa/build_disk:latest
exit 0
