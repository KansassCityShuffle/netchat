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

	# retrieve user informations
	if (( $# > 0 )); then get_options $@; fi
	if [ "$ports" = 0 ]; then ports="$default_ports"; fi
	if [ "$username" = 0 ]; then username="$USER"; fi

	get_network_infos

	# prepare file system
	netchat_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	if [ -d "${netchat_dir}/data" ]; then rm -Rf "${netchat_dir}/data"; fi
	mkdir -p "${netchat_dir}/data/${username}/home"
	mkfifo "${netchat_dir}/data/${username}/home/in"
	mkfifo "${netchat_dir}/data/${username}/home/out"
	mkfifo "${netchat_dir}/data/${username}/home/net_in"
	mkfifo "${netchat_dir}/data/${username}/home/net_out"

	if [ -d  "${netchat_dir}/log" ]; then rm -Rf "${netchat_dir}/log"; fi
	mkdir "${netchat_dir}/log"
	logfile="${netchat_dir}/log/netchat.log"
	touch "$logfile"

	# start interface and home "controller"
	./controllers/home_controller.sh "$username" "$user_addr" "$bcast_addr" "$ports" &
	home_pid=$!

	# Keep current session on filesystem
	session_folder="data/$username/session_infos"
	mkdir -p $session_folder
	echo "home" > "${session_folder}/current"
	echo "home" > "${session_folder}/sessions_list"

	# Start interface on "home" session
	screen -dmS "home" bash -c "./interface/interface.sh $username home"

	while [ -f "$session_folder/current" ]; do
		current=$(cat $session_folder/current)
		screen -r "$current"
	done
}

main $@
kill -15 $home_pid 2>>"$logfile"
exit 0
