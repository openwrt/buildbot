#!/bin/bash

export LC_ALL=C

buildbot_url="$1"
current_slave="$2"
current_builder="$3"
current_mode="$4"

running_builders="$(wget -qO- "${buildbot_url%/}/json/slaves/$current_slave?as_text=1" | sed -ne 's,^.*"builderName": "\(.*\)".*$,\1,p')"

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

	rm -f cleanup.sh
	rm -vrf sdk/ | while read entry; do
		case "$entry" in *directory:*)
			printf "."
		esac
	done

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
			if [ -d sdk ]; then
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
