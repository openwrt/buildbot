#!/usr/bin/env bash

[ -n "$BUILDSLAVE_NAME" ] || {
	echo "Please supply a name via --env BUILDSLAVE_NAME=XXX" >&2
	exit 1
}

[ -n "$BUILDSLAVE_PASSWORD" ] || {
	echo "Please supply a password via --env BUILDSLAVE_PASSWORD=XXX" >&2
	exit 2
}

rm -f /builder/buildbot.tac

/usr/bin/buildslave create-slave --force --umask=022 /builder \
    "$BUILDSLAVE_MASTER" "$BUILDSLAVE_NAME" "$BUILDSLAVE_PASSWORD"

echo "$BUILDSLAVE_ADMIN" > /builder/info/admin
echo "$BUILDSLAVE_DESCRIPTION" > /builder/info/host

unset BUILDSLAVE_ADMIN BUILDSLAVE_DESCRIPTION BUILDSLAVE_MASTER BUILDSLAVE_NAME BUILDSLAVE_PASSWORD

rm -f /builder/twistd.pid
exec /usr/bin/buildslave start --nodaemon /builder
