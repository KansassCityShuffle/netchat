#!/bin/bash
#
# Logging functions

# Log argument
# Usage: log <message>
function log()
{

	log_file=$(basename "${BASH_SOURCE[1]}")
	log_file="log/${log_file}.log"
	echo "(${BASH_SOURCE[1]}[${BASH_LINENO[1]}] ${FUNCNAME[1]}) [$(date +'%Y-%m-%d %T')] $@" >> $log_file
}

# Log from pipe
# Usage: <command> | log [file]
function logp()
{
	if [ $# -eq 1 ]; then
		log_file=$1
	else
		log_file=$(basename "${BASH_SOURCE[1]}")
		log_file="log/${log_file}.log"
	fi
    read data
	echo "(${BASH_SOURCE[1]}[${BASH_LINENO[1]}] ${FUNCNAME[1]}) $data" >> $log_file
}

# Log stream from pipe
# Usage: <command> | log [file]
function logs()
{
	if [ $# -eq 1 ]; then
		log_file=$1
	else
		log_file=$(basename "${BASH_SOURCE[1]}")
		log_file="log/${log_file}.log"
	fi
    while read data; do
        echo "(${BASH_SOURCE[1]}[${BASH_LINENO[1]}] ${FUNCNAME[1]}) $data" >> $log_file
    done
}
