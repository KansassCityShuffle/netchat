#!/bin/bash
source globals.sh


trap "rm -f session; echo signal >$in_pipe" EXIT

while [ -f session ]
do
	clear
	echo -ne " > "
	read cmd

	if [ "$cmd" == "quit" ] || [ "$cmd" == "exit" ]; then

		rm -f session
		echo -ne "[self] $cmd\n" > $in_pipe

	else

		echo -ne "[self] $cmd\n" > $in_pipe
		#echo "$cmd" > $kb_pipe

	fi
done

rm -f session
