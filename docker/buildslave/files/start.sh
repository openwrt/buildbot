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

/usr/bin/buildbot-worker create-worker --force --umask="0o22" /builder \
    "$BUILDSLAVE_MASTER" "$BUILDSLAVE_NAME" "$BUILDSLAVE_PASSWORD"

if [ "$BUILDSLAVE_TLS" = 1 ]; then
	sed -i \
		-e 's#(buildmaster_host, port, #(None, None, #' \
		-e 's#allow_shutdown=allow_shutdown#&, connection_string="TLS:%s:%d:trustRoots=/certs" %(buildmaster_host, port)#' \
		/builder/buildbot.tac
fi

echo "$BUILDSLAVE_ADMIN" > /builder/info/admin
echo "$BUILDSLAVE_DESCRIPTION" > /builder/info/host

unset BUILDSLAVE_ADMIN BUILDSLAVE_DESCRIPTION BUILDSLAVE_MASTER BUILDSLAVE_NAME BUILDSLAVE_PASSWORD

rm -f /builder/twistd.pid
exec /usr/bin/buildbot-worker start --nodaemon /builder
