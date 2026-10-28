#!/bin/sh
#
# Helper for 03-signing.t. It runs inside a container from the master image,
# because that image has the openssl, apk and signall.sh that releases use.
#
# Usage:
#   signing-fixtures.sh create <work_dir>
#       Inputs:  none.
#       Outputs: <work_dir>/signing_key.pem        private P-256 key
#                <work_dir>/public_keys/test.pub   matching public key
#                <work_dir>/config.ini             buildmaster config with the key
#                <work_dir>/unsigned.tar.gz        tarball with an unsigned
#                                                  packages.adb and sha256sums
#
#   signing-fixtures.sh sign <work_dir> <run_name>
#       Inputs:  the files made by "create".
#       Outputs: <work_dir>/<run_name>/packages.adb and sha256sums, as
#                produced by signall.sh from a fresh copy of unsigned.tar.gz.
#
#   signing-fixtures.sh tamper <work_dir>
#       Inputs:  <work_dir>/first_run/packages.adb, a signed index.
#       Outputs: <work_dir>/tampered/packages.adb, the same file with one
#                byte of the signed payload changed.

set -eu

# Byte offset inside the uncompressed index. The first 8 bytes are the file
# header and the next 4 the block header, so the signed data starts at 12.
# Offset 12 itself holds the compatibility version, which apk checks before
# the signature. Offset 16 is the root of the index, which apk reads only after
# the signature check, so changing it fails with "UNTRUSTED signature".
TAMPER_OFFSET=16

generate_key_pair() {
	work_dir="$1"

	mkdir -p "$work_dir/public_keys"
	openssl ecparam -name prime256v1 -genkey -noout \
		-out "$work_dir/signing_key.pem"
	openssl ec -in "$work_dir/signing_key.pem" -pubout \
		-out "$work_dir/public_keys/test.pub" 2> /dev/null
}

create_package() {
	work_dir="$1"

	mkdir -p "$work_dir/package_files/usr/share"
	echo hello > "$work_dir/package_files/usr/share/hello"

	apk mkpkg \
		--info name:hello \
		--info version:1.0-r0 \
		--info arch:x86_64 \
		--info description:"Package for the signing test" \
		--files "$work_dir/package_files" \
		--output "$work_dir/hello-1.0-r0.apk"
}

create_unsigned_tarball() {
	work_dir="$1"
	upload_dir="$work_dir/upload"

	mkdir -p "$upload_dir"
	apk mkndx --allow-untrusted \
		--output "$upload_dir/packages.adb" \
		"$work_dir/hello-1.0-r0.apk" > /dev/null

	# Same layout as the tarballs uploaded by phase1 and phase2
	(cd "$upload_dir" && sha256sum --binary packages.adb > sha256sums)
	tar -C "$upload_dir" -czf "$work_dir/unsigned.tar.gz" .
}

# Write a config.ini shaped like the production one: the PEM key spans
# several lines and the continuation lines are indented.
create_config_ini() {
	work_dir="$1"
	signing_key="$work_dir/signing_key.pem"

	{
		echo "[branch main]"
		echo "apk_key = $(head -n 1 "$signing_key")"
		tail -n +2 "$signing_key" | sed 's/^/\t/'
		# signall.sh reads back an empty key when it is the last entry in the
		# file, and then silently skips signing. This dummy entry works around
		# that known issue, which is to be fixed separately.
		echo "unused_option = 1"
	} > "$work_dir/config.ini"
}

create_fixtures() {
	work_dir="$1"

	mkdir -p "$work_dir"
	generate_key_pair "$work_dir"
	create_package "$work_dir"
	create_unsigned_tarball "$work_dir"
	create_config_ini "$work_dir"
}

sign_fresh_copy() {
	work_dir="$1"
	run_name="$2"
	tarball="$work_dir/$run_name.tar.gz"

	cp "$work_dir/unsigned.tar.gz" "$tarball"
	# signall.sh creates its scratch directory in the current directory
	(cd "$work_dir" && CONFIG_INI="$work_dir/config.ini" \
		/scripts/signall.sh "$tarball" main)

	mkdir -p "$work_dir/$run_name"
	tar -C "$work_dir/$run_name" -xzf "$tarball"
}

# A byte flipped in a compressed index can break decompression instead of the
# signature check. So decompress the index, flip a byte of the signed data and
# write the result uncompressed, which every apk reads.
tamper_with_payload() {
	work_dir="$1"
	signed_index="$work_dir/first_run/packages.adb"
	tampered_index="$work_dir/tampered/packages.adb"

	mkdir -p "$work_dir/tampered"
	python3 - "$signed_index" "$tampered_index" "$TAMPER_OFFSET" <<'PYTHON'
import sys
import zlib

signed_index, tampered_index, offset = sys.argv[1], sys.argv[2], int(sys.argv[3])

with open(signed_index, "rb") as index_file:
    signed_data = index_file.read()

# "ADB." starts an uncompressed index. "ADBd" starts a deflate-compressed one,
# followed by the raw deflate stream of the uncompressed index.
magic = signed_data[:4]
if magic == b"ADB.":
    index = bytearray(signed_data)
elif magic == b"ADBd":
    index = bytearray(zlib.decompress(signed_data[4:], -15))
else:
    sys.exit(f"{signed_index}: unsupported apk index format {magic!r}")

if index[:4] != b"ADB.":
    sys.exit(f"{signed_index}: decompressed data is not an apk index")
index[offset] ^= 0xFF

with open(tampered_index, "wb") as index_file:
    index_file.write(index)
PYTHON
}

usage() {
	echo "usage: $0 create|tamper <work_dir>" >&2
	echo "       $0 sign <work_dir> <run_name>" >&2
	exit 1
}

command="${1:-}"
work_dir="${2:-}"
run_name="${3:-}"

[ -n "$work_dir" ] || usage

case "$command" in
	create) create_fixtures "$work_dir" ;;
	sign)
		[ -n "$run_name" ] || usage
		sign_fresh_copy "$work_dir" "$run_name"
		;;
	tamper) tamper_with_payload "$work_dir" ;;
	*) usage ;;
esac
