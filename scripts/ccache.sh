#!/usr/bin/env bash

export LC_ALL=C

mkdir -p "$HOME/.ccache" || exit 1

grep -sq max_size "$HOME/.ccache/ccache.conf" || \
	echo "max_size = 10.0G" >> "$HOME/.ccache/ccache.conf" || exit 1

grep -sq compiler_check "$HOME/.ccache/ccache.conf" || \
	echo "compiler_check = %compiler% -dumpmachine; %compiler% -dumpversion" >> "$HOME/.ccache/ccache.conf" || exit 1

for dir in $(make --no-print-directory val.TOOLCHAIN_DIR val.STAGING_DIR val.STAGING_DIR_HOST V=s | grep staging_dir/); do
	if [ ! -L "$dir/ccache" ] || [ -L "$dir/ccache" -a ! -d "$dir/ccache" ]; then
		mkdir -vp "$dir" || exit 1
		rm -vrf "$dir/ccache" || exit 1
		ln -vs "$HOME/.ccache" "$dir/ccache" || exit 1
	fi
done

exit 0
