#!/usr/bin/env bash

chown buildbot:buildbot /builder

/usr/sbin/gosu buildbot "$@"
