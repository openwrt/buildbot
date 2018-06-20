#!/bin/bash -x

export LC_ALL=C

PV=`which pv`
RSYNC=rsync

if [[ -x $PV ]]; then
	$RSYNC "$@" | $PV -t -i 60 -f
else
	$RSYNC "$@"
fi
