#!/usr/bin/env bash

export LC_ALL=C

mkdir -p "$HOME/.ccache"

grep -sq max_size "$HOME/.ccache/ccache.conf" || \
	echo "max_size = 10.0G" >> "$HOME/.ccache/ccache.conf"

grep -sq compiler_check "$HOME/.ccache/ccache.conf" || \
	echo "compiler_check = %compiler% -dumpmachine; %compiler% -dumpversion" >> "$HOME/.ccache/ccache.conf"

for dir in $(make --no-print-directory val.TOOLCHAIN_DIR val.STAGING_DIR val.STAGING_DIR_HOST V=s | grep staging_dir/); do
	mkdir -p "$dir"
	test -L "$dir/ccache" || rm -rf "$dir/ccache"
	ln -s "$HOME/.ccache" "$dir/ccache"
done

./staging_dir/host/bin/ccache -s 2>/dev/null

exit 0
