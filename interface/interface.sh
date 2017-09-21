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
	screen -S $channel -c interface/screen.cfg

	logfile="$( pwd )/log/interface_${channel}.log"
}

main $@
exit 0
