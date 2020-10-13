#!/bin/bash

# $1: host
# $2: cmd


echo "====== [${1}] ======" 

if [[ -f $2 ]]; then
	ssh -o ConnectTimeout=10 root@$1 < ${2}  2>/dev/null
else
	cmd="ssh -o ConnectTimeout=10 root@$1 \"${2}\"  2>/dev/null"
	eval $cmd
fi

echo "--------------------"
echo "                    "
