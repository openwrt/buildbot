#!/usr/bin/env bash

[ -n "$BUILDWORKER_NAME" ] || {
	echo "Please supply a name via --env BUILDWORKER_NAME=XXX" >&2
	exit 1
}

[ -n "$BUILDWORKER_PASSWORD" ] || {
	echo "Please supply a password via --env BUILDWORKER_PASSWORD=XXX" >&2
	exit 2
}

rm -f /builder/buildbot.tac

/opt/venv/bin/buildbot-worker create-worker \
	--force \
	--umask="0o22" \
	--connection-string="SSL:$BUILDWORKER_MASTER" \
	/builder \
	"$BUILDWORKER_MASTER" \
	"$BUILDWORKER_NAME" \
	"$BUILDWORKER_PASSWORD"

echo "$BUILDWORKER_ADMIN" > /builder/info/admin
echo "$BUILDWORKER_DESCRIPTION" > /builder/info/host

unset BUILDWORKER_ADMIN BUILDWORKER_DESCRIPTION BUILDWORKER_MASTER BUILDWORKER_NAME BUILDWORKER_PASSWORD

rm -f /builder/twistd.pid
exec /opt/venv/bin/buildbot-worker start --nodaemon /builder
