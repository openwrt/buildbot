#!/bin/bash

export LC_ALL=C

master_url="$1"
current_slave="$2"
current_builder="$3"
current_mode="$4"

running_builders="$(wget -qO- "${master_url%/}/json/slaves/$current_slave?as_text=1" | sed -ne 's,^.*"builderName": "\(.*\)".*$,\1,p')"

find /tmp/ -maxdepth 1 -mtime +1 '(' -name 'npm-*' -or -name 'jsmake-*' ')' -print0 | xargs -0 -r rm -vr

is_running() {
	local running_builder
	for running_builder in $running_builders; do
		if [ "${running_builder//\//_}" = "${1//\//_}" ]; then
				return 0
		fi
	done
	return 1
}

do_cleanup() {
	printf "Cleaning up '$current_builder' work directory"

	if [ -d .git ]; then
		echo " using git"
		git reset --hard HEAD
		git clean -f -d -x
	else
		find . -mindepth 1 -maxdepth 1 | while read entry; do
			rm -vrf "$entry" | while read entry2; do
				case "$entry2" in *directory[:\ ]*)
					printf "."
				esac
			done
		done
	fi

	echo ""
}

#
# Sanity check, current builder should be in running builders list
#

if ! is_running "$current_builder"; then
	echo "Current builder '$current_builder' not found in current builders list, aborting cleanup."
	exit 1
fi


#
# Clean up leftovers
#

if [ "$current_mode" = full ]; then
(
	if ! flock -x -w 2700 200; then
		echo "Unable to obtain exclusive lock, aborting cleanup."
		exit 1
	fi

	for build_dir in ../*; do

		build_dir="$(readlink -f "$build_dir")"

		if [ -z "$build_dir" ] || [ -L "$build_dir" ] || [ ! -d "$build_dir/build" ]; then
			continue
		fi

		current_builder="${build_dir##*/}"

		if is_running "$current_builder"; then
			echo "Skipping currently active '$current_builder' work directory."
			continue
		fi

		(
			cd "$build_dir/build"
			do_cleanup
		)
	done

) 200>../cleanup.lock

#
# Clean up current build
#

else
	if [ -d build ]; then (
		cd build
		do_cleanup
	); fi
fi

exit 0
