#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

main()
{
	echo "main"
	cur_user=$SC_USER
	cur_chan=$SC_CHANNEL

	in_pipe=data/$cur_user/$cur_chan/in

	while [ -p $in_pipe ]
	do
		read -d "$(echo -e '\004')" input < $in_pipe
		echo -e "$input"
	done
}

main $@
exit 0
