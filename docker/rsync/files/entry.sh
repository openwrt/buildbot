#!/bin/sh

(
	echo "use chroot = yes"
	echo "[${SHARE_NAME:-data}]"
	echo "log file = /dev/null"
	echo "uid = ${SHARE_UID:-1000}"
	echo "gid = ${SHARE_GID:-1000}"
	echo "path = /data"
	echo "read only = false"
	echo "write only = false"
	echo "comment = ${SHARE_COMMENT:-Rsync data share}"

	if [ -n "$SHARE_USER" -a -n "$SHARE_PASSWORD" ]; then
		echo "auth users = $SHARE_USER"
		echo "secrets file = /rsyncd.secrets"
	fi
) > /rsyncd.conf

if [ -n "$SHARE_USER" -a -n "$SHARE_PASSWORD" ]; then
	echo "$SHARE_USER:$SHARE_PASSWORD" > /rsyncd.secrets
	chmod 0600 /rsyncd.secrets
fi

chown "${SHARE_UID:-1000}:${SHARE_GID:-1000}" /data

rm -f /tmp/rsyncd.pid

exec /usr/bin/rsync --daemon --no-detach --config=/rsyncd.conf --log-file=/dev/stdout --dparam=pidfile=/tmp/rsyncd.pid "$@"
