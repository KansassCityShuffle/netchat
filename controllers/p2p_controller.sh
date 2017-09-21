#!/usr/bin/env bash

# Controller for p2p conversations
# Usage: p2p_controller.sh <username> <channel> <peer_ip>
#
# Reads from "out_pipe" (user input) and write to "in_pipe" user echo and
# peer input


# Connect to distant listener
# Usage: start_client <peer_ip> <peer_port> <out_pipe> <resulting_pid>
function start_client()
{
	# Start socat, linking the pipe with the socket
	socat PIPE:$3 TCP:$1:$2 &
	# Write PID of socat into last argument
	eval "$4=$!"
}

#Create listener
# Usage: start_server <port> <in_pipe> <resulting_pid>
function start_server()
{
	# Start socat, linking the pipe with the socket
	socat TCP-LISTEN:$1,reuseaddr PIPE:$2 &
	# Write PID of socat into last argument
	eval "$3=$!"
}

main()
{
	# Init variables
	cur_user=$1
	cur_chan=$2
	loc_out=data/$cur_user/$cur_chan/out
	loc_in=data/$cur_user/$cur_chan/in
	net_out=data/$cur_user/$cur_chan/net_out
	net_in=data/$cur_user/$cur_chan/net_in
	peer_name="unknown"
	srv_pid=''

	# TODO:SELECT USER PORT
	user_port=24001

	# Create pipes
	mkfifo $loc_in
	mkfifo $loc_out
	mkfifo $net_in
	mkfifo $net_out

	echo "** Connecting..." > $in_pipe

	# Start the listening server
	start_server $user_port $net_in srv_pid

	# Send "connect" packet to peer
	# TODO: DEFINE PACKET CONTENTS
	echo "CONNECT $cur_user $user_port" | socat - udp-sendto:$peer_ip:24000

	# Wait for answer packet
	connected=0
	while [ $connected -eq 0 ];	do
		# TODO: TIMEOUT HANDLING
		read line < $net_in
		if [[ $line == *"CONNECTED"* ]]; then
  			connected=1
		fi
	done

	echo "** Connected to $peer_name ($peer_ip:$peer_port)" > $in_pipe

	while [[ -p $out_pipe ] && [ -p $in_pipe ]]; do
		read line < $out_pipe
		echo "[$cur_user] $line"
	done

}


main $@
exit 0
