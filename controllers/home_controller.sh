#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

logfile="$( pwd )/log/home_controller.log"

usage()
{
  echo "Usage: $0 username user_addr bcast_addr ports"
}

read_from_room()
{
  while [ -p $in ]; do
    read input < $in
    case "$input" in
      "discover")
                # echo "$disco" | socat - udp-sendto:"$bcast_addr":24000,broadcast
                echo '' > "$out"
                ;;
      "list")
                echo '' > "$out"
                ;;
      "infos")
                if [[ -p "$out" ]]; then
                  echo -e " Username : ${username} \nUser addr : ${user_addr} \nBcast addr : ${bcast_addr}\nPorts range : ${ports}" > "$out"
                else
                  echo "[\"infos\" command] out pipe (named in) is break;broken." > $logfile
                  exit 1
                fi
                ;;
      "connect")
                ;;
      "exit")
                if [[ -p "$out" ]]; then
                  echo "exit" > "$out"
                  rm -f "$in"
                  break
                fi
                ;;
    esac
  done
}

read_from_network()
{
  while [ -p $net_in ]; do

    read net_input < $net_in
    echo "$net_input" > $logfile

    username_re="[[:alnum:]]{1,10}"
    addr_re="[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}"
    disco_re="^(DISCO{1}):($username_re):($addr_re)$"
    unidisco_re="^(UDISCO{1}):($username_re):($addr_re)$"

    if [[ "$net_input" =~ $disco_re ]]; then
      echo -e ${BASH_REMATCH[1]} > "$out"
      echo -e ${BASH_REMATCH[2]} > "$out"
      echo -e ${BASH_REMATCH[3]} > "$out"
      # if [[ ${BASH_REMATCH[3]} != $user_addr ]]; then
        # echo "$unidisco" | socat - udp-sendto:${BASH_REMATCH[3]}:24000,unicast
      # fi
    elif [[ "$net_input" =~ $unidisco_re ]]; then
      echo -e ${BASH_REMATCH[1]} > "$out"
      echo -e ${BASH_REMATCH[2]} > "$out"
      echo -e ${BASH_REMATCH[3]} > "$out"
    else
      echo "not matched $net_input" > "$out"
    fi

  done
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

  # Listen for ever
  socat -u udp-recv:24000,reuseaddr PIPE:"$net_in" &
  listener_pid=$!

  # Discover
   echo "$disco" | socat - udp-sendto:${bcast_addr}:24000,broadcast

  # Do job until pipes are broken
  read_from_network &
  read_from_room
}

main $@
kill -15 $listener_pid
exit 0
