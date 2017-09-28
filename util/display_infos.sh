#!/usr/bin/env bash

#================
# USAGE FUNCTIONS
#================

scriptinfo()
{
	headfilter="^#-"
	[[ "$1" = "usg" ]] && headfilter="^#+"
	[[ "$1" = "ful" ]] && headfilter="^#[%+]"
	[[ "$1" = "inf" ]] && headfilter="^#-"
	head -${SCRIPT_HEADSIZE:-99} ${0} | grep -e "${headfilter}" | sed -e "s/${headfilter}//g" -e "s/\${SCRIPT_NAME}/${SCRIPT_NAME}/g";
}
usage()
{
	printf "Usage: "
	scriptinfo usg
}
usagefull()
{
	scriptinfo ful
}
infos()
{
	scriptinfo inf
}
