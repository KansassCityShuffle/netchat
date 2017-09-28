#!/bin/bash

file_seslist="data/$1/session_infos/sessions_list"
file_current="data/$1/session_infos/current"

line=$(cat $file_seslist | tr '\n' ' ' | sed s'/.$//')
cur_sesh=$(cat $file_current)

final=$(echo $line | sed "s/\b${cur_sesh}\b/[${cur_sesh}]/")

echo $final
