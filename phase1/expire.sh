#!/bin/bash

max_lifetime="$1"

tree_birth="$(date --reference=tree.timestamp +%s 2>/dev/null)"
tree_age="$(( $(date +%s) - ${tree_birth:-0} ))"

if [ $max_lifetime -le 0 ]; then
	echo "No tree expiry set."

elif [ $tree_age -ge $max_lifetime ]; then
	echo "The build tree reached its maximum lifetime, cleaning up."
	find . -mindepth 1 -maxdepth 1 -print0 | xargs -r -0 rm -vrf | while read entry; do
		printf "."
	done

	mkdir build

	echo ""
	echo "Writing new timestamp"
	date +%s > tree.timestamp

else
	echo "The build tree is not expired."
fi

exit 0
