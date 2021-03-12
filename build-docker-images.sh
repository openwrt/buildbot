#!/bin/sh

docker build -t openwrtorg/buildmaster -f docker/buildmaster/Dockerfile .
docker push openwrtorg/buildmaster

docker build -t openwrtorg/buildworker -f docker/buildworker/Dockerfile .
docker push openwrtorg/buildworker
