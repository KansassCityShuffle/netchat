#!/usr/bin/env bash

#!/usr/bin/env bash

main()
{
	cur_user=$SC_USER
	cur_chan=$SC_CHANNEL

	out_pipe=data/$cur_user/$cur_chan/out

	while [ -f $out_pipe ]
	do
		clear
		echo -ne " > "
		read cmd
		echo $cmd > $out_pipe
	done
}

main $@
exit 0
