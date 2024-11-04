#!/usr/bin/env bash

for dir in /master /config /certs /home/buildbot; do
  [ -d "$dir" ] || continue 

  chown --recursive buildbot:buildbot "$dir"
  chmod 0700 "$dir"
done

if [ -S "/home/buildbot/.gnupg/S.gpg-agent" ]; then
	chown buildbot:buildbot /home/buildbot/.gnupg/S.gpg-agent
	chmod 0600 /home/buildbot/.gnupg/S.gpg-agent
fi

/usr/sbin/gosu buildbot /start.sh "$@"
