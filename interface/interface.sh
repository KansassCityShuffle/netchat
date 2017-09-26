#!/usr/bin/env bash

# Creates a dual-panel interface using screen
# Usage: interface.sh <username> <channel>

set -o errexit
set -o pipefail
set -o nounset

main()
{
	user=$1
	channel=$2

	# Export variables to "traverse" screen (cannot call screen with arguments)
	export SC_USER=$user
	export SC_CHANNEL=$channel

	if hash rlwrap 2>/dev/null; then
        screen -S $channel -c interface/screen_rl.cfg
    else
        screen -S $channel -c interface/screen.cfg
    fi


	logfile="$( pwd )/log/interface_${channel}.log"
}

main $@
exit 0
