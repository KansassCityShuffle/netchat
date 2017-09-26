#!/usr/bin/env bash

# Controller for p2p conversations
#
# Usage: p2p_controller.sh <user_name> <peer_name> <user_ip> <port> <mode>
#                          <peer_ip> [<peer_port>]
#
#        mode can be either "emission" or "reception"
#        "peer_port" is used only in reception mode
#
# Reads from "loc_out" (user input) and write to "loc_in" user echo and
# peer input

source util/logging.sh
trap cleanup EXIT


# Special logging: specify current session for clarity
# Usage: slog <message>
function slog()
{
	log "[${cur_user}-${peer_name}] $@"
}

# Connect to distant listener
# Usage: start_client <peer_ip> <peer_port> <net_out> <resulting_pid>
function start_client()
{
	# Start socat, linking the pipe with the socket
	cli_log_file="log/p2p_socat_cli_${cur_user}_${peer_name}.log"
	socat -d -d -d PIPE:$3 TCP:$1:$2,retry=5 >> ${cli_log_file} 2>&1 &
	# Write PID of socat
	spid=$(jobs -p)
	slog "socat client pid = $spid"
	cli_pid=$spid
}

# Create listener
# Usage: start_server <port> <net_in>
function start_server()
{
	# TODO: put "resulting_pid" to -1 if socat not working

	# Start socat, linking the pipe with the socket
	srv_log_file="log/p2p_socat_srv_${cur_user}_${peer_name}.log"
	socat -d -d -d TCP-LISTEN:$1,reuseaddr PIPE:$2 >> ${srv_log_file} 2>&1 &
	# Write PID of socat
	spid=$(jobs -p)
	slog "socat server pid = $spid"
	srv_pid=$spid
}


# Send packet to peer and log it
function send()
{
	slog "sent \"$1\""
	echo "$1" > $net_out
}


# Usage
function usage()
{
	echo "Usage: p2p_controller.sh <username> <channel> <user_ip> <port_range>"
	echo "                         <mode> <peer_ip> [<peer_port>]"
}


# Cleanup (for real trap)
function cleanup()
{
	slog "Cleaning up on exit"

	# Terminate background running socat's

	if [ "$srv_pid" != "-1" ]; then
		kill -15 $srv_pid 2>&1 | logp $logfile
	fi
	if [ "$cli_pid" != "-1" ]; then
		kill -15 $cli_pid 2>&1 | logp $logfile
	fi


	# Exit with error
	exit 1
}


function main()
{
	slog "Arguments: $@"

	if [ "$#" -lt 6 ]; then
		usage
		exit 1
	fi

	# Init variables
	cur_user=$1
	cur_chan=$2
	logfile="log/p2p_controller_${cur_user}_${cur_chan}.log"
	mkdir -p "data/$cur_user/$cur_chan"
	loc_out="data/$cur_user/$cur_chan/out"      # interface -> controller
	loc_in="data/$cur_user/$cur_chan/in"        # controller -> interface
	net_out="data/$cur_user/$cur_chan/net_out"  # controller -> socket
	net_in="data/$cur_user/$cur_chan/net_in"    # socket -> controller
	peer_name=$2
	srv_pid=-1
	cli_pid=-1
	user_ip=$3
	user_port=$4
	mode=$5
	peer_ip=$6
	session_valid=1

	if [ "$mode" = "reception" ] && [ "$#" -lt 7 ]; then
		usage
		exit 1
	elif [ "$mode" = "reception" ]; then
		peer_port=$7
	else
		peer_port=-1
	fi


	# Create pipes
	mkfifo $loc_in 2>&1 | logp $logfile
	mkfifo $loc_out 2>&1 | logp $logfile
	mkfifo $net_in 2>&1 | logp $logfile
	mkfifo $net_out 2>&1 | logp $logfile


	# Start the listening server
	start_server $user_port $net_in
	if [ "$srv_pid" -eq "-1" ]; then
		session_valid=0
		echo "** Could not start data server" > $loc_in
	fi


	# We initialized the session
	if [[ "$mode" = "emission" ]] && [ "$session_valid" -eq "1" ]; then
		# Wait for answer packet
		connected=0
		while [ $connected -eq 0 ];	do

			# TODO: TIMEOUT HANDLING
			read line < $net_in
			slog "got packet: $line"

			# Parse message
			IFS=':' read -r -a tokens <<< "$line"
			if [[ "${tokens[0]}" = "OKCONNECT" ]]; then
				peer_name="${tokens[1]}"
				peer_ip="${tokens[2]}"
				peer_port="${tokens[3]}"
				connected=1
			else
				echo "** Peer reply is invalid" > $loc_in
				slog "Could not parse packet"
				session_valid=0
			fi

			# Connect to peer listener
			start_client $peer_ip $peer_port $net_out
			if [ "$cli_pid" = "-1" ]; then
				echo "** Could not start data client" > $loc_in
				session_valid=0
			else
				# Send OKCONNECT to peer
				send "OKCONNECT:$cur_user:$user_ip:$user_port"
			fi
		done

	# We were "called"
	# TODO: "NOCONNECT"
	elif [[ "$mode" = "reception" ]] && [ "$session_valid" -eq "1" ]; then

		# Connect to peer listener
		start_client $peer_ip $peer_port $net_out
		if [ "$cli_pid" = "-1" ]; then
			echo "** Could not start data client" > $loc_in
			session_valid=0
		else
			# Send OKCONNECT to peer
			send "OKCONNECT:$cur_user:$user_ip:$user_port"

			# Wait for peer reply on listener
			connected=0
			while [ $connected -eq 0 ];	do
				# TODO: TIMEOUT HANDLING
				read line < $net_in

				# Parse message
				IFS=':' read -r -a tokens <<< "$line"
				if [[ "${tokens[0]}" = "OKCONNECT" ]]; then
					connected=1
				else
					echo "** Peer reply is invalid" > $loc_in
					session_valid=0
				fi
			done
		fi

	fi

	if [ "$session_valid" -eq "0" ]; then
		echo "** Error during handshake, aborting." > $loc_in
	else
		echo "** Connected to $peer_name ($peer_ip:$peer_port)" > $loc_in

		while [ -p $loc_out ] && [ -p $loc_in ]; do
			read -t 0.1 user_line <> $loc_out

			if [[ ! -z "${user_line// }" ]]; then
				if [[ "$user_line" = "exit" ]]; then
					break
				fi
				echo "[$cur_user] $user_line" > $loc_in
				send "$user_line"
				user_line=""
			fi


			read -t 0.1 peer_line <> $net_in
			if [[ ! -z "${peer_line// }" ]]; then
				echo "[$peer_name] $peer_line" > $loc_in
				peer_line=""

				# TODO: Handle some commands like "quit"

			fi


		done
	fi

	cleanup
}


main $@
exit 0
