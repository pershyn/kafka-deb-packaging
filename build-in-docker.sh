#!/bin/bash
set -e

DOCKER_IMAGE="kafka-deb-builder"
DOCKER_CONTAINER=kafka-deb-builder
SCRIPT=build.sh

docker build -t ${DOCKER_IMAGE} .
docker run -ti --name ${DOCKER_CONTAINER} --rm -v $(shell pwd):/usr/src/app ${DOCKER_IMAGE} /bin/bash ./${SCRIPT}
