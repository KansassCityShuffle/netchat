#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# TODO : move this in config file
default_ports="24001-30000"

usage()
{
	echo "Usage: $0 [-p <MINPORT-MAXPORT>] [-u <USERNAME>]"
}

are_ports()
{
	local re="^[0-9]{1,5}\-[0-9]{1,5}$"
	if [[ "$1" =~ $re ]]; then
		return 0
	else
		return 1
	fi
}

is_username()
{
	local re="^[a-zA-Z]{1,10}$"
	if [[ "$1" =~ $re ]]; then
		return 0
	else
		return 1
	fi
}

get_network_infos()
{
	iface=$( route | grep "default" | awk -F " " '{ print $NF }' )
	user_addr=$( ip -f inet -o address | grep "$iface" | awk -F " |/" '{print $7}')
	bcast_addr=$( ip -f inet -o address | grep "$iface" | awk -F " |/" '{print $10}')
}

get_options()
{
	while getopts ":p:u:" opt; do
		case $opt in
			p)
				if are_ports "$OPTARG"; then
					ports="$OPTARG"
				fi
				;;
			u)
				if is_username "$OPTARG"; then
					username="$OPTARG"
				fi
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

main()
{
	ports=0
	user_addr=0
	bcast_addr=0
	username=0

	if (( $# > 0 )); then get_options $@; fi

	if [ "$ports" = 0 ]; then ports="$default_ports"; fi
	if [ "$username" = 0 ]; then username="$USER"; fi

	get_network_infos

<<COMMENT
	echo "User name : $username"
	echo "Local ports range : $ports"
	echo "Local addr : $user_addr"
	echo "Bcast addr : $bcast_addr"
COMMENT

	netchat_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	if [ -d "${netchat_dir}/data" ]; then rm -Rf "${netchat_dir}/data"; fi
	mkdir -p "${netchat_dir}/data/${username}/home"
	mkfifo "${netchat_dir}/data/${username}/home/in"
	mkfifo "${netchat_dir}/data/${username}/home/out"

	./controllers/home_controller.sh "$username" "$user_addr" "$bcast_addr" "$ports" &
	./interface/interface.sh "$username" "home"
}
main $@
exit 0
