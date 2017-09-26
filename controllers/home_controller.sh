#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

logfile="$( pwd )/log/home_controller.log"
touch "$logfile"

usage()
{
  echo "Usage: $0 username user_addr bcast_addr ports"
}

# Exit codes
# 0 : normal exit
# 1 : not handle error exit
# 2 : out pipe broken
# 3 : in pipe broken
# 4 : no port available
OUT_ERR="broken out pipe"
PORT_ERR="no port available in specified range"
handle_error()
{
  local lineno="$1"
  local message="$2"
  local code="$3"
  if [[ -n "$message" ]]; then
    echo "Error on line ${lineno}: ${message}; exiting with status code ${code}" >> "$logfile"
  else
    echo "Error on line ${lineno}; exiting with status code ${code}" >> "$logfile"
  fi

  # if ps -p $listener_pid; then kill -15 $listener_pid 2>>"$logfile"; done
  # if ps -p $reader_pid; then kill -15 $reader_pid 2>>"$logfile"; done
  # exit "$code"
}

# $1 new_host
# $2 known_hosts
is_known_in()
{
  local match="$1"; shift
  for entry; do
    [[ "$entry" == "$match" ]] && return 0;
  done
  return 1
}

# $1 name
# $2 ip
set_discovered_user()
{
  readarray known_hosts < "$known_hosts_file"
  new_host="$1:$2"
  if [ ${#known_hosts[@]} -eq 0 ]; then
    #known_hosts+=("$new_host")
    echo "$new_host" > "$known_hosts_file"
    return 0
  elif ! is_known_in "$new_host" "${known_hosts[@]}" ; then
    echo "$new_host" > "$known_hosts_file"
    return 0
  fi
  return 1
}

# $1 min_port
# $2 max_port
get_available_port()
{
  local port=0
  for port in $(seq $min_port $max_port); do
    echo -ne "\035" | telnet 127.0.0.1 $port > /dev/null 2>&1;
    [ $? -eq 1 ] && echo "unused $port" >> "$logfile" && break;
  done
  echo $port
}

read_from_room()
{
  local conn_re="^(connect{1})([[:space:]]{1,5})([[:digit:]]{1,5})$"
  local conn_no=-1
  while [ -p $in ]; do
    read input < $in
    if [[ "$input" =~ $conn_re ]]; then
      input=${BASH_REMATCH[1]}
      conn_no=${BASH_REMATCH[3]}
    fi
    case "$input" in
      "discover")
                if [[ -p "$out" ]]; then
                  echo "$disco" | socat - udp-sendto:"$bcast_addr":24000,broadcast >>"$logfile" 2>&1
                else
                  handle_error ${LINENO} ${OUT_ERR} 2
                fi
                ;;
      "list")
                if [[ -p "$out" ]]; then
                  echo -e "[LIST]" > "$out"
                  readarray known_hosts < "$known_hosts_file"
                  if [ ${#known_hosts[@]} -eq 0 ]; then
                    echo -e "Hosts list is empty" > "$out"
                    echo -e '' > "$out"
                  else
                    i=1
                    for host in ${known_hosts[@]}; do
                      echo -e "$i ) $host" > "$out"
                    done
                    echo -e '' > "$out"
                  fi
                else
                  handle_error ${LINENO} ${OUT_ERR} 2
                fi
                ;;
      "infos")
                if [[ -p "$out" ]]; then
                  echo -e '[INFOS]' > "$out"
                  echo -e "Username : ${username} \n\
User addr : ${user_addr} \n\
Bcast addr : ${bcast_addr}\n\
Ports range : ${ports}" > "$out"
                else
                  handle_error ${LINENO} ${OUT_ERR} 2
                fi
                ;;
      "connect")
                echo -e "[CONNECT]" > "$out"
                readarray known_hosts < "$known_hosts_file"
                if (( $conn_no <= 0 || $conn_no > ${#known_hosts[@]} )); then
                    echo -e "Please type \"connect\" followed by the user ID you want to chat with." > "$out"
                    echo -e "Type \"list\" to see users ID, name and IP." > "$out"
                else
                  local next_port conn_request remote_host host_infos
                  next_port=$min_port
                  next_port=$( get_available_port $min_port $max_port )
                  conn_request="$connect:$next_port"
                  remote_host=${known_hosts[$conn_no - 1]}
                  remote_ip=$(echo $remote_host | cut -d ":" -f 2)
                  ./p2p_controller.sh
                  echo "$conn_request" | socat -d -d -d - udp-sendto:"$remote_ip":24000 >>"$logfile" 2>&1
                fi
                ;;
      "help")
                if [[ -p "$out" ]]; then
                    echo -e "[HELP]" > "$out"
                else
                    handle_error ${LINE_NO} ${OUT_ERR} 2
                fi
                ;;
      "exit")
                if [[ -p "$out" ]]; then
                  echo "exit" > "$out"
                  rm -f "$in"
                  break
                else
                  handle_error ${LINENO} ${OUT_ERR} 2
                fi
                ;;
      *)
                echo -e "Unknown command" > "$out"
                ;;
    esac
  done
  echo "Exiting room." >>"$logfile"
}

read_from_network()
{
  local username_re addr_re port_re disco_re unidisco_re connect_re
  username_re="[[:alnum:]]{1,10}"
  addr_re="[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}"
  port_re="[[:digit:]]{1,5}"
  disco_re="^(DISCO{1}):($username_re):($addr_re)$"
  unidisco_re="^(UDISCO{1}):($username_re):($addr_re)$"
  connect_re="^(CONNECT{1}):($username_re):($addr_re):($port_re)$"

  while [ -p $net_in ]; do

    if [ ! -p "$out" ]; then
      handle_error ${LINENO} ${OUT_ERR} 2
    fi

    read net_input <> $net_in 2>>"$logfile"

    if [[ "$net_input" =~ $disco_re ]]; then
      echo -e "[DISCO RECEIVED]" > "$out"
      echo -e ${BASH_REMATCH[1]} > "$out"
      echo -e ${BASH_REMATCH[2]} > "$out"
      echo -e ${BASH_REMATCH[3]} > "$out"
      if [[ ${BASH_REMATCH[3]} != $user_addr ]]; then
        if set_discovered_user ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}; then
          echo -e "Host added" > "$out"
          echo "$unidisco" | socat -d -d -d - udp-sendto:${BASH_REMATCH[3]}:24000 >>"$logfile" 2>&1
        else
          echo -e "Host not added" > "$out"
        fi
      fi
    elif [[ "$net_input" =~ $unidisco_re ]]; then
      echo -e "[UDISCO RECEIVED]" > "$out"
      echo -e ${BASH_REMATCH[1]} > "$out"
      echo -e ${BASH_REMATCH[2]} > "$out"
      echo -e ${BASH_REMATCH[3]} > "$out"
      if set_discovered_user ${BASH_REMATCH[2]} ${BASH_REMATCH[3]}; then
        echo -e "Host added" > "$out"
      else
        echo -e "Host not added" > "$out"
      fi
    elif [[ "$net_input" =~ $connect_re ]]; then
      echo -e "[CONNECT RECEIVED]" > "$out"
      echo -e ${BASH_REMATCH[0]} > "$out"
      ./p2p_controller
    else
      echo "Other message received $net_input" > "$out"
    fi

  done
  echo "Exiting network reader" >>"$logfile"
}

main()
{
  # Retreive script parameters
  if [[ $# != 4 ]]; then
    usage
    exit 1
  else
    username="$1"
    user_addr="$2"
    bcast_addr="$3"
    ports="$4"
    ports_re="([[:digit:]]{1,5})-([[:digit:]]{1,5})"
    if [[ "$ports" =~ $ports_re ]]; then
      min_port=${BASH_REMATCH[1]}
      max_port=${BASH_REMATCH[2]}
    fi
  fi

  # Store pipes paths
  netchat_dir="$( pwd )"
  out="${netchat_dir}/data/${username}/home/in"
  in="${netchat_dir}/data/${username}/home/out"
  net_out="${netchat_dir}/data/${username}/home/net_in"
  net_in="${netchat_dir}/data/${username}/home/net_out"

  # Build socat packets
  disco="DISCO:${username}:${user_addr}"
  unidisco="UDISCO:${username}:${user_addr}"
  connect="CONNECT:${username}:${user_addr}"

  # Make known hosts directory
  known_hosts_file="${netchat_dir}/data/${username}/session_infos/known_hosts"
  touch "$known_hosts_file"
  echo "operator:10.2.240.69" > "$known_hosts_file"

  # Listen for ever
  socat -d -d -d -u udp-recv:24000,reuseaddr PIPE:"$net_in" >>"$logfile" 2>&1 &
  listener_pid=$!

  # Auto discover
  echo "$disco" | socat -d -d -d - udp-sendto:${bcast_addr}:24000,broadcast >>"$logfile" 2>&1

  # Do job until pipes are broken
  read_from_network &
  reader_pid=$!
  read_from_room
}

main $@
echo "Terminating process..." >>"$logfile"
kill -15 $listener_pid 2>>"$logfile"
kill -15 $reader_pid 2>>"$logfile"
echo "Process terminated" >>"$logfile"
rm -f "data/$username/session_infos/current"
exit 0
