#!/usr/bin/env bash


wait_for_session()
{

}

main()
{
	# Make loops loop
	touch vars/running

	# Create "home" session
	screen -c ./screen.cfg -S home -t netchat

}

main $@
exit 0
