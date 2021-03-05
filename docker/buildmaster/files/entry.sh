#!/usr/bin/env bash

chown --recursive buildbot:buildbot /master /config /certs
chmod 0700 /master /config /certs

/usr/sbin/gosu buildbot /start.sh "$@"
