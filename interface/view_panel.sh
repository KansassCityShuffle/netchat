#!/usr/bin/env bash
# set -o errexit
set -o pipefail
set -o nounset

main()
{
	clear
	cur_user=$SC_USER
	cur_chan=$SC_CHANNEL

	in_pipe=data/$cur_user/$cur_chan/in

	logfile="$( pwd )/log/view_${cur_chan}.log"

	while [ -p $in_pipe ]
	do
		read -d "$(echo -e '\004')" input < $in_pipe
		if [[ "$input" = "exit" ]]; then
	  	rm -f "$in_pipe"
			break
		else
			echo -e "$input"
		fi
	done
}

main $@
exit 0
