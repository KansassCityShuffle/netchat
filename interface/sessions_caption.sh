#!/bin/bash

bold=$(tput bold)
normal=$(tput sgr0)

file_seslist="data/$1/session_infos/sessions_list"
file_current="data/$1/session_infos/current"

line=$(cat $file_seslist | tr '\n' ' ' | sed s'/.$//')
cur_sesh=$(cat $file_current)

final=$(echo $line | sed "s/\b${cur_sesh}\b/[${bold}${cur_sesh}${normal}]/")

echo $final
