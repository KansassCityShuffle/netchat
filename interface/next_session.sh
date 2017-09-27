#!/usr/bin/env bash
# Switch sessions based on current session, sessions_list and direction
# Usage : next_session.sh

source util/logging.sh

# Searches for an element in an array of strings and echo it's index
# Returns 0 when found, 1 when not found
# Echoes -1 when not found
# Usage : indexOf <element> <array>
function indexOf()
{
	match=$1
	shift
	array=($@)

	num=0

	for element in "${array[@]}"; do
		if [[ "$element" = "$match" ]]; then
			echo $num
			return 0
		else
			num=$(($num+1))
		fi
	done

	echo "-1"
	return 1
}


function main()
{
	file_current="data/$SC_USER/session_infos/current"
	file_seslist="data/$SC_USER/session_infos/sessions_list"

	if [ ! -f "$file_seslist" ]; then
		log "Sessions list not found (SC_USER=$SC_USER)"
		exit 1
	fi

	if [ ! -f "$file_current" ]; then
		log "Current session not found (SC_USER=$SC_USER)"
		exit 1
	fi

	i=0
	while read line; do
		sessions[$i]="$line"
		i=$((i+1))
	done < $file_seslist

	current=$(cat $file_current)

	log "${#sessions[@]} sessions, current is \"$current\""

	index=$(indexOf "$current" "${sessions[@]}")
	if [[ $index -gt -1 ]]; then
		log "$current is session $index of ${#sessions[@]} "
	else
		log "Could not find $current in sessions, aborting"
		exit 1
	fi

	if [[ $index -eq $((${#sessions[@]}-1)) ]]; then
		nextIdx=0
	else
		nextIdx=$(($index+1))
	fi

	screen -d $current > /dev/null 2>&1

	current=${sessions[nextIdx]}
	echo "$current" > $file_current
	log "Current session is now $current"

	exit 0
}

main $@
exit 0






main()
{
	direction=$1

}

main $@
exit 0
