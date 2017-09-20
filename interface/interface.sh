#!/usr/bin/env bash




main()
{
	user=$1
	channel=$2

	screen -S $channel -c interface/screen.cfg

}


main $@
exit 0
