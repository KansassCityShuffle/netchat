#!/usr/bin/env bash

main()
{
	cur_user=$SC_USER
	cur_chan=$SC_CHANNEL

	in_pipe=data/$cur_user/$cur_chan/in

	while [ -p $in_pipe ]
	do
		read input < $in_pipe
		echo $input
	done
}

main $@
exit 0
