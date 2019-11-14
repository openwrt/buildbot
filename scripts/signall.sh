#!/usr/bin/env bash

tarball="$1"

tmpdir="signall.$$"
tarball="$(readlink -f "$tarball")"

finish() { rm -rf "$tmpdir"; exit $1; }

iniget() {
	local file="$1" section="$2" option="$3"

	sed -rne '
		/\['"$section"'\]/,$ {
			/^[ \t]*'"$option"'[ \t]*=[ \t]*/ {
				s/^[^=]+=[ \t]*//; h;
				:c; n;
				/^([ \t]|$)/ {
					s/^[ \t]+//; H;
					b c
				};
				x; p; q
			}
		}
	' "$file" | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}'
}

trap "finish 255" HUP INT TERM

if [ ! -f "$tarball" ] || [ ! -f "${CONFIG_INI:-config.ini}" ]; then
	echo "Usage: [CONFIG_INI=...] $0 <tarball>" >&2
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

GPGKEY="$(iniget "${CONFIG_INI:-config.ini}" gpg key)"
GPGPASS="$(iniget "${CONFIG_INI:-config.ini}" gpg passphrase)"
GPGCOMMENT="$(iniget "${CONFIG_INI:-config.ini}" gpg comment)"

USIGNKEY="$(iniget "${CONFIG_INI:-config.ini}" usign key)"
USIGNCOMMENT="$(iniget "${CONFIG_INI:-config.ini}" usign comment)"

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
			--homedir "$(readlink -f "$tmpdir/gpg")" \
			${loopback:+--pinentry-mode loopback --no-tty --passphrase-fd 0} \
			${GPGPASS:+--passphrase-file "$(readlink -f "$tmpdir/gpg.pass")"} \
			${GPGCOMMENT:+--comment="$GPGCOMMENT"} \
			-o "{}.asc" "{}" \; || finish 4
fi

if [ -n "$USIGNKEY" ]; then
	USIGNID="$(echo "$USIGNKEY" | base64 -d -i | dd bs=1 skip=32 count=8 2>/dev/null | od -v -t x1 | sed -rne 's/^0+ //p' | tr -d ' ')"

	if ! echo "$USIGNID" | grep -qxE "[0-9a-f]{16}"; then
		echo "Invalid usign key specified" >&2
		finish 5
	fi

	umask 077
	printf "untrusted comment: %s\n%s\n" "${USIGNCOMMENT:-key ID $USIGNID}" "$USIGNKEY" > "$tmpdir/usign.sec"

	umask 022
	find "$tmpdir/tar/" -type f -not -name "*.asc" -and -not -name "*.sig" -exec \
		signify-openbsd -S -s "$(readlink -f "$tmpdir/usign.sec")" -m "{}" \; || finish 5
fi

tar -C "$tmpdir/tar/" -czf "$tarball" . || finish 6

finish 0
