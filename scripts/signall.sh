#!/usr/bin/env bash

tarball="$1"

tmpdir="signall.$$"
tarball="$(readlink -f "$tarball")"

finish() { rm -rf "$tmpdir"; exit $1; }

trap "finish 255" HUP INT TERM

if [ ! -f "$tarball" ]; then
	echo "Usage: [GPGKEY=... [GPGCOMMENT=... [GPGPASS=...]]] [USIGNKEY=... [USIGNCOMMENT=...]] $0 <tarball>" >&2
	finish 1
fi

[ ! -e "$tmpdir" ] || {
	echo "Temporary directory $tmpdir already exists!" >&2
	finish 2
}

umask 077
mkdir "$tmpdir" "$tmpdir/tar" "$tmpdir/gpg" "$tmpdir/gpg/private-keys-v1.d" || finish 2

umask 022
chmod 0755 "$tmpdir/tar"
tar -C "$tmpdir/tar/" -xzf "$tarball" || finish 3

loopback=""

case "$(gpg --version | head -n1)" in
	*\ 2.*) loopback=1 ;;
esac

if echo "$GPGKEY" | grep -q "BEGIN PGP PRIVATE KEY BLOCK"; then
	umask 077
	echo "$GPGPASS" > "$tmpdir/gpg.pass"
	echo "$GPGKEY" | gpg --batch --homedir "$tmpdir/gpg" \
		${loopback:+--pinentry-mode loopback --no-tty --passphrase-fd 0} \
		${GPGPASS:+--passphrase-file "$tmpdir/gpg.pass"} \
		--import - || finish 4

	umask 022
	find "$tmpdir/tar/" -type f -not -name "*.asc" -and -not -name "*.sig" -exec \
		gpg --no-version --batch --yes -a -b \
			--homedir "$tmpdir/gpg" \
			${loopback:+--pinentry-mode loopback --no-tty --passphrase-fd 0} \
			${GPGPASS:+--passphrase-file "$tmpdir/gpg.pass"} \
			${GPGCOMMENT:+--comment="$GPGCOMMENT"} \
			-o "{}.asc" "{}" \; || finish 4
fi

USIGNID="$(echo "$USIGNKEY" | base64 -d -i | dd bs=1 skip=32 count=8 2>/dev/null | od -v -t x1 | sed -rne 's/^0+ //p' | tr -d ' ')"

if echo "$USIGNID" | grep -qxE "[0-9a-f]{16}"; then
	umask 077
	printf "untrusted comment: %s\n%s\n" "${USIGNCOMMENT:-key ID $USIGNID}" "$USIGNKEY" > "$tmpdir/usign.key"

	umask 022
	find "$tmpdir/tar/" -type f -not -name "*.asc" -and -not -name "*.sig" -exec \
		signify-openbsd -S -s "$(readlink -f "$tmpdir/usign.key")" -m "{}" \; || finish 5
fi

tar -C "$tmpdir/tar/" -czf "$tarball" . || finish 6

finish 0
