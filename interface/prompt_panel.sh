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

	clear
	echo -ne " > "
	while [ -p $out_pipe ]
	do
		read -t 0.5 cmd && clear && echo -ne " > "
		if [ ! -z "${cmd// }" ]; then
			echo "$cmd" > "$out_pipe"
		fi
	done
}

main $@
exit 0
