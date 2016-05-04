#!/bin/bash

current_slave="$1"
current_builder="$2"
current_mode="$3"

running_builders="$(wget -qO- "http://builds.lede-project.org:8010/json/slaves/$current_slave?as_text=1" | sed -ne 's,^.*"builderName": "\(.*\)".*$,\1,p')"

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
	echo "Cleaning up '$current_builder' work directory..."

	find . -mindepth 1 -maxdepth 1 -print0 | xargs -r -0 rm -vrf | while read entry do
		printf "."
	done
}

#
# Sanity check, current builder should be in running builders list
#

if ! is_running "$current_builder"; then
	echo "Current builder '$current_builder' not found in current builders list, aborting cleanup."
	exit 0
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

	for build_dir in ../../*; do

		build_dir="$(readlink -f "$build_dir")"

		if [ -z "$build_dir" ] || [ ! -d "$build_dir/build/sdk" ]; then
			continue
		fi

		current_builder="${build_dir##*/}"

		if is_running "$current_builder"; then
			echo "Skipping currently active '$current_builder' work directory."
			continue
		fi

		(
			cd "$build_dir/build"

			#if [ -n "$(git status --porcelain | grep -v update_hostkey.sh | grep -v cleanup.sh)" ]; then
			if [ -d sdk ] || [ -f sdk.tar.bz2 ]; then
				do_cleanup
			else
				echo "Skipping clean '$current_builder' work directory."
			fi
		)
	done

) 200>../../cleanup.lock

#
# Clean up current build
#

else
	do_cleanup
fi

exit 0
