#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

main()
{
	cur_user=$SC_USER
	cur_chan=$SC_CHANNEL

	out_pipe=data/$cur_user/$cur_chan/out

	logfile="$( pwd )/log/prompt_${cur_chan}.log"

	while [ -p $out_pipe ]
	do
		clear
		echo -ne " > "
		read cmd
		echo -e "$cmd" > "$out_pipe"
		if [[ "$cmd" = "exit" ]]; then
			break
		fi
	done
}

main $@
exit 0
