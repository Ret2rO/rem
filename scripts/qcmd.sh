#!/bin/bash
#
# description: 这是一个并行执行命令的脚本 
#
# author: linxd
# date: 2020/08/25
#
#=====================================


############ variables ##############

cmd=$1
hosts=$2
exclu=$3


if [[ -z "$cmd" || -z "$hosts" ]]; then
	echo "param error, command $cmd $hosts.file excluKeyWord"
	exit 1
fi

# define your home path
homepath=""
path=$(cd $(dirname $0); pwd)

if [[ ! -z "$homepath" ]]; then
	path=$homepath
fi

if [[ ! -d "$path/log" ]]; then
	mkdir -p $path/log
fi


logFile=$path/log/execute.log
seq=0
threadFlag="qcmdflag"

############ function ############### 

isDone()
{
	a=$(ps -ef| grep $1 | grep $threadFlag )
	if [[ -z $a ]]; then
		return 0
	else
		return 1
	fi
}

progress()
{
	echo -en "\b\b\b\b\b\b\b\b\b\b\b\b\b\bprogress: "`echo $1*100/$2 | bc `'%'
}

############ main script #############
{
	echo " start ---------------"
	# support explict ip
	if [[ ! -f $hosts ]]; then
		echo "$hosts" > /tmp/.t.hosts
		hosts="/tmp/.t.hosts"
	fi
	
	
	# execute task on backgroud
	ips=$(cat $hosts| tr '\n' ' ')
	[[ -f $path/log/.t.0.log ]] && rm -f $path/log/.t.*
	
	for h in $ips
	do
		if [[ $h =~ ^#.* ]]; then
			continue
		fi
		if [[ ! -z $exclu && $h == *$exclu* ]]; then
			continue
		fi
		
		bash $path/_cmd.sh $h "$cmd" $threadFlag > $path/log/.t.$seq.log 2>/dev/null &
		seq=$(($seq+1))
	done
	
	# monitor task status
	task_list=$(ps -ef|grep $threadFlag | grep -v 'grep '$$threadFlag | awk '{print $2}')
	arr=(${task_list[@]})
	seq=0
	list=""
	size=${#arr[@]}
	doneCnt=0
	progress $doneCnt $size

	while true
	do
		for i in $task_list
		do
			isDone $i
			if [[ $? -ne 0 ]]; then
				list=$list" "$i
			else
				doneCnt=$(($doneCnt+1))
				progress $doneCnt $size
			fi
		done

		if [[ -z "$list" ]]; then
				echo " "
				cat $path/log/.t*
				break
		fi

		task_list=$list
		list=""
		seq=$(($seq+1))

		if [[ $seq -gt 30 ]]; then
			echo "******* timeout *******"
			cat $path/log/.t*
			
			# kill
			for j in $task_list
			do
				kill -9 $j
			done
			exit 1
		fi

		sleep 1
	done

	echo " end ----------------"
}
