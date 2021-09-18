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
threadFlag="qcmdflag"$(whoami)$(date +%s)


############ function ############### 

isDone()
{
	a=$(ps -ef| awk '{print $2}' | grep $1 )
	if [[ -z $a ]]; then
		return 0
	else
		return 1
	fi
}

width=`stty size| awk '{print $2}'`
width=$(($width-12))
line=$(seq $width| awk '{print "#"}' | tr '\n' ','| sed 's/,//g')

progress()
{
    index=`echo $1*100/$2 | bc`
    len=`echo $1*$width/$2|bc`
    printf "  [%-${width}s][%d%%]\r" "${line:0:$len}" "$index"
}


printResult()
{
        cd $path/log/
        cat $(ls -a | grep threadFlag | sort -t'.'  -k3,3 -n)
        cd $path
}

genCmd()
{
if [[ ! -f $path/_cmd.sh ]]; then

cat << EOF > $path/_cmd.sh
#!/bin/bash

	hosts=\$1
	cmd=\$2
	echo "====== [\$hosts] ======"
	if [[ -f \$cmd ]]; then
	        ssh -o ConnectTimeout=10 root@\$hosts < \$cmd  2>/dev/null
	else
	        cmd="ssh -o ConnectTimeout=10 root@\$hosts \"\$cmd\"  2>/dev/null"
	        eval \$cmd
	fi
	echo "--------------------"
	echo "                    "
	#statements
EOF
fi

}



############ main script #############
{
	echo " start ---------------"
	# support explict ip
	if [[ ! -f $hosts ]]; then
		echo "$hosts" > /tmp/.t.hosts
		hosts="/tmp/.t.hosts"
	fi
	genCmd
	
	# execute task on backgroud
	ips=$(cat $hosts| tr '\n' ' ')
	[[ -f $path/log/.threadFlag.0.log ]] && rm -f $path/log/.threadFlag.*
	
	for h in $ips
	do
		if [[ $h =~ ^#.* ]]; then
			continue
		fi

		bash $path/_cmd.sh $h "$cmd" $threadFlag > $path/log/.threadFlag.$seq.log 2>/dev/null &
		seq=$(($seq+1))
	done

	# monitor task status
	task_list=$(ps -ef|grep $threadFlag | grep -v 'grep' | awk '{print $2}')

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
				printResult
				break
		fi

		task_list=$list
		list=""
		seq=$(($seq+1))

		if [[ $seq -gt 30 ]]; then
			echo "******* timeout *******\n"
			printResult
			
			# kill
			for j in $task_list
			do
				kill -9 $j
			done
			exit 1
		fi

		sleep 1
	done

}

