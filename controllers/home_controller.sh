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
  while [ -p $in_pipe ]; do
    read input < $in_pipe
    case "$input" in
      "list")
                ;;
      "infos")
                if [[ -p "$out_pipe" ]]; then
                  echo -e " Username : ${username} \nUser addr : ${user_addr} \nBcast addr : ${bcast_addr}\nPorts range : ${ports}" > "$out_pipe"
                else
                  echo "Out pipe is broken." > $logfile
                  break;
                fi
                ;;
      "connect")
                ;;
      "exit")
                if [[ -p "$out_pipe" ]]; then
                  echo "exit" > "$out_pipe"
                  rm -f "$in_pipe"
                  break
                fi
                ;;
    esac
  done
  # echo "Out / In pipe are broken. Closing Screen home session." > $logfile
  # screen -S home -X quit
}

main()
{
  if [[ $# != 4 ]]; then
    usage
    exit 1
  else
    username="$1"
    user_addr="$2"
    bcast_addr="$3"
    ports="$4"
  fi

  netchat_dir="$( pwd )"
  out_pipe="${netchat_dir}/data/${username}/home/in"
  in_pipe="${netchat_dir}/data/${username}/home/out"
  read_from_room
}

main $@
exit 0
