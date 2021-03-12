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

use_tls=""
[ "$BUILDWORKER_TLS" = 1 ] && use_tls="--use-tls"
/usr/local/bin/buildbot-worker create-worker --force --umask="0o22" $use_tls /builder \
    "$BUILDWORKER_MASTER" "$BUILDWORKER_NAME" "$BUILDWORKER_PASSWORD"

if [ "$BUILDWORKER_TLS" = 1 ]; then
	sed -i \
		-e 's#(buildmaster_host, port, #(None, None, #' \
		-e 's#allow_shutdown=allow_shutdown#&, connection_string="SSL:%s:%d" %(buildmaster_host, port)#' \
		/builder/buildbot.tac
fi

echo "$BUILDWORKER_ADMIN" > /builder/info/admin
echo "$BUILDWORKER_DESCRIPTION" > /builder/info/host

unset BUILDWORKER_ADMIN BUILDWORKER_DESCRIPTION BUILDWORKER_MASTER BUILDWORKER_NAME BUILDWORKER_PASSWORD

rm -f /builder/twistd.pid
exec /usr/local/bin/buildbot-worker start --nodaemon /builder
