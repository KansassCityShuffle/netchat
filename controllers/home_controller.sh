#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

usage()
{
  echo "Usage: $0 username user_addr bcast_addr ports"
}

write_to_room()
{
  if [ -p $out_pipe ]; then
    for item in "$@"; do
      echo -ne "$item " > "$out_pipe"
    done
  fi
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
                  echo "Username : ${username} \n User addr : ${user_addr}" > "$out_pipe"
                else
                  break;
                fi
                ;;
      "connect")
                ;;
      "exit")
                rm -f $out_pipe
                rm -f $in_pipe
                exit 0
                ;;
    esac
  done
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
