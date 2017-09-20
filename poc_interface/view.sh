#!/bin/bash
source globals.sh

clear

echo "********"
echo "**"
echo "** Welcome to netchat !"
echo "** Commands to get started:"
echo "**     exit/quit : exit the session"
echo "**"
echo "********"

while [ -f session ]
do
	read input <$in_pipe
	echo $input
done
