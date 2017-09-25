#!/bin/env bash

# Search for a free port in a specified range
# Usage : find_port.sh <range>

source util/logging.sh

if [ $# -lt 1 ]; then
	echo "Usage : find_port.sh <range>"
	exit 1
fi

IFS='-' read -r -a tokens <<< "$1"
user_port_min=${tokens[0]}
user_port_max=${tokens[1]}

user_port=$user_port_min
while [ $user_port -le $user_port_max ]; do
	netstat -vatn | grep $user_port > /dev/null
	if [ "$?" -eq 0 ]; then
		user_port=$(($user_port + 1))
	else
		echo $user_port
		exit 0
	fi
done

echo "-1"
