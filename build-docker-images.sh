#!/bin/sh

docker build -t openwrtorg/buildmaster -f docker/buildmaster/Dockerfile .
docker push openwrtorg/buildmaster

docker build -t openwrtorg/buildslave -f docker/buildslave/Dockerfile .
docker push openwrtorg/buildslave
