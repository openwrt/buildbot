#!/usr/bin/env bash

tarball="$1"
keyid="$2"
passfile="$3"
comment="$4"

tmpdir="signall.$$"
tarball="$(readlink -f "$tarball")"

finish() { rm -rf "$tmpdir"; exit $1; }

trap "finish 255" HUP INT TERM

if [ ! -f "$tarball" ]; then
	echo "Usage: $0 <tarball> [<keyid> [<passfile> [<comment>]]]"
	finish 1
fi

mkdir "$tmpdir" || finish 2
tar -C "$tmpdir/" -xzf "$tarball" || finish 3
find "$tmpdir/" -type f -not -name "*.gpg" -exec gpg --no-version --batch --yes -a -b ${keyid:+-u "$keyid"} ${comment:+--comment="$comment"} ${passfile:+--passphrase-file "$passfile"} -o "{}.gpg" "{}" \; || finish 4
tar -C "$tmpdir/" -czf "$tarball" . || finish 5

finish 0
