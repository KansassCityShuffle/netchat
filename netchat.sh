#!/usr/bin/env bash
#=================================================================
# HEADER
#=================================================================
#%
#% SYNOPSIS
#+	${SCRIPT_NAME} [-hv] [-p <MINPORT-MAXPORT>] [-u <USERNAME>]
#%
#% DESCRIPTION
#%	Netchat provides decentralized chat features in local networks.
#%	It relies on Socat utility and Screen for multiple shells
#%	management.
#%
#% OPTIONS
#%	-h                     Print this help.
#%	-p <MINPORT-MAXPORT>   Set a range of ports available for TCP
#%	                       sockets.
#%	                       The default value is 24001-30000.
#%	-u <USERNAME>          Set the name people in Netchat will see
#%	                       when you are connected.
#%	                       The default value is your session login.
#%	-v                     Print script informations
#%
#% EXAMPLES
#%	${SCRIPT_NAME} -p 25500-26000 -u JohnSmith51
#%
#==================================================================
#- IMPLEMENTATION
#-	version		${SCRIPT_NAME} 0.0.1
#-	authors		Alban CHAZOT, Lisa AUBRY
#-	copyright	Copyright (c)
#-	license		GNU General Public License
#- 	Git url		https://github.com/KansassCityShuffle/netchat
#-
#==================================================================
# HISTORY
#		28/09/2017 : lisa : Adding scripts headers
#
#==================================================================
# DEBUG OPTIONS
#		set -n # Uncomment to check your syntax (without execution)
#		set -x # Uncomment to debug this script
#
#==================================================================
# END_OF_HEADER
#==================================================================

set -o errexit
set -o pipefail
set -o nounset

#==============
# SET VARIABLES
#==============
SCRIPT_OPTS=":hvu:p:"
SCRIPT_HEADSIZE=$(head -200 ${0} | grep -n "^# END_OF_HEADER" | cut -f1 -d:)
SCRIPT_NAME="$(basename ${0})"
DEFAULT_PORTS="24001-30000"

#==============
# USAGE FUNCT
#==============
source util/display_infos.sh

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
	local re="^[[:alnum:]]{1,20}$"
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
	while getopts "${SCRIPT_OPTS}" opt; do
		case $opt in
			p)
				if are_ports "$OPTARG"; then
					ports="$OPTARG"
				else
					usage
					exit 1
				fi
				;;
			u)
				if is_username "$OPTARG"; then
					username="$OPTARG"
				else
					usage
					exit 1
				fi
				;;
			h)
				usagefull
				exit 0
				;;
			v)
				infos
				exit 0
				;;
			:)
				echo "ERROR: -$OPTARG: requires an argument"
				usage
				exit 1
				;;
			?)
				echo "ERROR: -$OPTARG: unknown option"
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
	if [ "$ports" = 0 ]; then ports="${DEFAULT_PORTS}"; fi
	if [ "$username" = 0 ]; then username="${USER}"; fi

	get_network_infos

	# prepare file system
	netchat_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	if [ -d "${netchat_dir}/data/${username}" ]; then rm -Rf "${netchat_dir}/data/${username}"; fi
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
	./controllers/home_controller.sh "$username" "$user_addr" "$bcast_addr" "$ports" >/dev/null 2>&1 &
	home_pid=$!

	# Keep current session on filesystem
	session_folder="data/$username/session_infos"
	mkdir -p $session_folder
	echo "home" > "${session_folder}/current"
	echo "home" > "${session_folder}/sessions_list"
	export SC_USER=${username}

	# Start interface on "home" session
	screen -dmS "home" -c "interface/outer.cfg" bash -c "./interface/interface.sh $username home" > /dev/null

	while [ -f "$session_folder/current" ]; do
		current=$(cat $session_folder/current)
		screen -A -q -r "$current" > /dev/null 2>&1
	done
}

main $@
kill -15 $home_pid 2>>"$logfile"
exit 0
