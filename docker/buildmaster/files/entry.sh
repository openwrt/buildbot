#!/usr/bin/env bash

for dir in /master /config /certs; do
  [ -d "$dir" ] || continue 

  chown --recursive buildbot:buildbot "$dir"
  chmod 0700 "$dir"
done

/usr/sbin/gosu buildbot /start.sh "$@"
