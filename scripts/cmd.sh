#!/bin/bash

echo "start-----------"


cmd=$1
hosts=$2
exclu=$3

# TODO define your home path
homepath=""

if [[ -z "$cmd" || -z "$hosts" ]]; then
	echo "param error, command $cmd $hosts.file $excluKeyWord"
	exit 1
fi

path=$(cd $(dirname $0); pwd)

if [ ! -d "${homepath}/log"]; then
  mkdir -p ${homepath}/log
fi

if [ ! -d "$homepath"]; then
  homepath=$path
fi

logFile=${homepath}/log/execute.log


# if host is string
if [[ ! -f $hosts ]]; then
  echo "$hosts" > /tmp/t.hosts
  hosts=/tmp/t.hosts
fi

ips=$(cat $hosts| tr '\n' ' ')


for h in $ips
do
	if [[ $h =~ ^#.* ]]; then
		continue
	fi
	if [[ ! -z $exclu && $h == *$exclu* ]]; then
		continue
	fi

  echo "====== [${h}] ======" | tee -a $logFile
	if [[ -f $cmd ]]; then
    ssh -o ConnectTimeout=10 root@$h < ${cmd}	 | tee -a $logFile  2>/dev/null
	else
    ssh -o ConnectTimeout=10 root@$h "${cmd}"  | tee -a $logFile  2>/dev/null
	fi
  echo "                    "                  | tee -a $logFile
done

echo "end-----------------"
