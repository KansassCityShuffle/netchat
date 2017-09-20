#!/bin/bash
source globals.sh

mkfifo $in_pipe
mkfifo $kb_pipe

touch session

screen -c ./screen.cfg -S netchat -t netchat

rm -f $in_pipe
rm -f $kb_pipe
