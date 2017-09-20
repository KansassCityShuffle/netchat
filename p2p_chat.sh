#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

usage()
{
	echo "Usage: $0 [-a [ip]] [-p [port]] [-n [username]]"
}

is_port()
{
	local re="^[0-9]{1,5}$"
	if [[ "$1" =~ $re ]]; then
		return 0
	else
		return 1
	fi
}

is_addr()
{
	local re="^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$"
	if [[ "$1" =~ $re ]]; then
		return 0
	else
		return 1
	fi
}

get_options()
{
	while getopts "p:a:n:" opt; do
		case $opt in
			p)
				if [[ "$OPTARG" = "DEFAULT" ]]; then
					port=10222
				elif is_port "$OPTARG"; then
					port="$OPTARG"
				fi
				;;
			a)
				if [[ "$OPTARG" = "DEFAULT" ]]; then
					addr="10.2.240.192"
				elif is_addr "$OPTARG"; then
					addr="$OPTARG"
				fi
				;;
			n)
				name="$OPTARG"
				;;
			:)
				echo "Error: -$OPTARG: requires an argument"
				usage
				exit 1
				;;
			?)
				echo "Error: -$OPTARG: unknown option"
				usage
				exit 1
				;;
		esac
	done
}

get_port()
{
	echo -n "Type remote port, followed by [ENTER]: "
        read port
        until is_port "$port"; do
		echo -n "Please type a valid port number one or (q) for escape : "
                read port
		if [[ "$port" == "q" ]]; then exit 0; fi
        done
}

get_addr()
{
	echo -n "Type remote IP address, followed by [ENTER]: "
	read addr
        until is_addr "$addr"; do
		echo -n "Please type a valid IP or (q) for escape : "
		read addr
		if [[ "$addr" == "q" ]]; then exit 0; fi
	done
}

connect()
{
	echo "Connect with remote listener..."
}

start_chat()
{
	echo "Starting chat..."
}

exit_chat()
{
	echo "Exit chat..."
}

main()
{
	port=0
	addr=0
	name=0

	if [ $# > 0 ]; then get_options $@; fi

	if [ "$port" = 0 ]; 	then get_port; 	fi
	if [ "$addr" = 0 ]; 	then get_addr; 	fi
	if [ "$name" = 0 ];	then get_name; 	fi

	# echo "Connect with remote listener..."
	# nc -l "$ip" "$port"
}

main $@
exit 0
