#!/usr/bin/env bash

tarball="$1"
keyid="$2"
comment="$3"

tmpdir="signall.$$"
tarball="$(readlink -f "$tarball")"

finish() { rm -rf "$tmpdir"; exit $1; }

trap "finish 255" HUP INT TERM

if [ ! -f "$tarball" ]; then
	echo "Usage: [GNUPGHOME=... [PASSFILE=...]] $0 <tarball> [<keyid> [<comment>]]"
	finish 1
fi

umask 022

mkdir "$tmpdir" || finish 2
tar -C "$tmpdir/" -xzf "$tarball" || finish 3

find "$tmpdir/" -type f -not -name "*.asc" -exec gpg \
	--no-version --batch --yes -a -b \
	${keyid:+-u "$keyid"} \
	${comment:+--comment="$comment"} \
	${GNUPGHOME:+--homedir "$GNUPGHOME"} \
	${PASSFILE:+--passphrase-file "$PASSFILE"} \
	-o "{}.asc" "{}" \; || finish 4

tar -C "$tmpdir/" -czf "$tarball" . || finish 5

finish 0
