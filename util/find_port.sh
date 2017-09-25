#!/bin/env bash

# Search for a free port in a specified range
# Usage : find_port.sh <range>


IFS='-' read -r -a tokens <<< "$4"
user_port_min=${tokens[0]}
user_port_max=${tokens[1]}

user_port=$user_port_min
free_found=0
while [ $free_found -eq 0 ] && [ $user_port -le $user_port_max ]; do
	netstat -vatn | grep $user_port > /dev/null
	if [ "$?" -eq 0 ]; then
		user_port=$(($user_port + 1))
	else
		free_found=1
	fi
done
