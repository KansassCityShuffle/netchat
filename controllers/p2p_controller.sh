#!/usr/bin/env bash

# Controller for p2p conversations
#
# Usage: p2p_controller.sh <username> <channel> <user_ip> <mode> <peer_ip>
#                          [<peer_port>]
#        mode can be either "emission" or "reception"
#        "peer_port" is used only in reception mode
#
# Reads from "loc_out" (user input) and write to "loc_in" user echo and
# peer input


# Connect to distant listener
# Usage: start_client <peer_ip> <peer_port> <net_out> <resulting_pid>
function start_client()
{
	# TODO: put "resulting_pid" to -1 if socat not working

	# Start socat, linking the pipe with the socket
	socat PIPE:$3 TCP:$1:$2 &
	# Write PID of socat into last argument
	eval "$4=$!"
}

# Create listener
# Usage: start_server <port> <net_in> <resulting_pid>
function start_server()
{
	# TODO: put "resulting_pid" to -1 if socat not working

	# Start socat, linking the pipe with the socket
	socat TCP-LISTEN:$1,reuseaddr PIPE:$2 &
	# Write PID of socat into last argument
	eval "$3=$!"
}

main()
{
	# Init variables
	loc_out=data/$cur_user/$cur_chan/out      # interface -> controller
	loc_in=data/$cur_user/$cur_chan/in        # controller -> interface
	net_out=data/$cur_user/$cur_chan/net_out  # controller -> socket
	net_in=data/$cur_user/$cur_chan/net_in    # socket -> controller
	cur_user=$1
	cur_chan=$2
	peer_name="unknown"
	srv_pid=-1
	cli_pid=-1
	user_ip=$3
	user_port=24001 # TODO:SELECT USER PORT
	mode=$4
	peer_ip=$5
	session_valid=1

	if [ "$#" -eq 6 ]; then
		peer_port=$6
	else
		peer_port=-1
	fi

	# Create pipes
	mkfifo $loc_in
	mkfifo $loc_out
	mkfifo $net_in
	mkfifo $net_out

	echo "** Connecting..." > $loc_in

	# Start the listening server
	start_server $user_port $net_in srv_pid
	if [ "$srv_pid" -eq "-1" ]; then
		session_valid=0
		echo "** Could not start data server" > $loc_in
	fi

	# We initialized the session
	if [[ "$mode" = "emission" ]] && [ "$session_valid" -eq "1"]; then
		# Send "connect" packet to peer
		echo "CONNECT:$cur_user:$user_ip:$user_port" | socat - udp-sendto:$peer_ip:24000

		# Wait for answer packet
		connected=0
		while [ $connected -eq 0 ];	do

			# TODO: TIMEOUT HANDLING
			read line < $net_in

			# Parse message
			IFS=':' read -r -a tokens <<< "$line"
			if [[ "${tokens[0]}" = "OKCONNECT" ]]; then
				peer_ip="${tokens[2]}"
				peer_port="${tokens[3]}"
				connected=1
			else
				echo "** Peer reply is invalid" > $loc_in
				session_valid=0
			fi

			# Connect to peer listener
			start_client $peer_ip $peer_port $net_out cli_pid
			if [ "$cli_pid" -eq "-1" ]; then
				echo "** Could not start data client" > $loc_in
				session_valid=0
			else
				# Send OKCONNECT to peer
				echo "OKCONNECT:$cur_user:$user_ip:$user_port" > $net_out
			fi
		done

	# We were "called"
	# TODO: "NOCONNECT"
	elif [[ "$mode" = "reception" ]] && [ "$session_valid" -eq "1"]; then

		# Connect to peer listener
		start_client $peer_ip $peer_port $net_out cli_pid
		if [ "$cli_pid" -eq "-1" ]; then
			echo "** Could not start data client" > $loc_in
			session_valid=0
		else
			# Send OKCONNECT to peer
			echo "OKCONNECT:$cur_user:$user_ip:$user_port" > $net_out

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

		while [[ -p $loc_out ] && [ -p $loc_in ]]; do
			read line < $loc_out
			echo "[$cur_user] $line" > $loc_in
			echo "[$cur_user] $line" > $net_out

			# TODO: Handle some commands like "quit"

		done
	fi

	# Terminate background running socat's
	kill -15 $srv_pid
	kill -15 $cli_pid

}


main $@
exit 0
