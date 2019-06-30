#!/usr/bin/env bash

tarball="$1"
keyid="$2"
comment="$3"

tmpdir="signall.$$"
tarball="$(readlink -f "$tarball")"

finish() { rm -rf "$tmpdir"; exit $1; }

trap "finish 255" HUP INT TERM

if [ ! -f "$tarball" ]; then
	echo "Usage: [GNUPGHOME=... [PASSFILE=...]] [USIGNKEY=... [USIGNCOMMENT=...]] \\"
	echo "  $0 <tarball> [<keyid> [<comment>]]"
	finish 1
fi

umask 022

mkdir "$tmpdir" || finish 2
tar -C "$tmpdir/" -xzf "$tarball" || finish 3

loopback=""

case "$(gpg --version | head -n1)" in
	*\ 2.*) loopback=1 ;;
esac

find "$tmpdir/" -type f -not -name "*.asc" -and -not -name "*.sig" -exec gpg \
	--no-version --batch --yes -a -b \
	${loopback:+--pinentry-mode loopback --no-tty --passphrase-fd 0} \
	${keyid:+-u "$keyid"} \
	${comment:+--comment="$comment"} \
	${GNUPGHOME:+--homedir "$GNUPGHOME"} \
	${PASSFILE:+--passphrase-file "$PASSFILE"} \
	-o "{}.asc" "{}" \; || finish 4

export USIGNID="$(echo "$USIGNKEY" | base64 -d -i | dd bs=1 skip=32 count=8 2>/dev/null | od -v -t x1 | sed -rne 's/^0+ //p' | tr -d ' ')"

if echo "$USIGNID" | grep -qxE "[0-9a-f]{16}"; then
	find "$tmpdir/" -type f -not -name "*.asc" -and -not -name "*.sig" -exec sh -c \
		'printf "untrusted comment: %s\n%s\n" "${USIGNCOMMENT:-key ID $USIGNID}" "$USIGNKEY" | \
			signify-openbsd -S -s - -m "{}"' \; || finish 5
fi

tar -C "$tmpdir/" -czf "$tarball" . || finish 6

finish 0
