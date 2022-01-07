#!/bin/bash

flag=""
pid=`ps -ef|grep "${flag}" | grep -v grep | awk '{if($3!=1) print $2}'`

echo "TIME                         PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND" > /tmp/top.log


while true
do
    if [ ! -z "$pid" ]; then
        echo -n "`date`" >> /tmp/top.log
        top -b -n 1 | grep flare-app | grep $pid >> /tmp/top.log
    fi
    sleep 1
    pid=`ps -ef|grep flare-nodes/0/apps/nhLog | grep -v grep | awk '{if($3!=1) print $2}'`
done
