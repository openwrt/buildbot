#!/usr/bin/env bash

chown buildbot:buildbot /master

/usr/sbin/gosu buildbot /start.sh "$@"
