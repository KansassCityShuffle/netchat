#!/bin/bash
source globals.sh

while [ -f session ]
do
	read kinput <$kb_pipe
done
