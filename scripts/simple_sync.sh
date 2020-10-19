#!/bin/sh

############### variables ###############
path=$(cd $(dirname $0); pwd)

host_group=''
local_dir=''
dest_dir=''
ip_file=''
t=30  # 超时



msg=" [-g {host_group}|-f {ip file}]  -l {local-dir} -d {dest-dir}"

while true ; do
    case "$1" in
    -f|--ip-file) ip_file=$2; shift 2;;
    -g|--group) host_group=$2; shift 2;;
    -l|--local-dir) local_dir=$2; shift 2;;
    -d|--dest-dir) dest_dir=$2; shift 2;;
    -t|--timeout) t=$2; shift 2;;
    -h|--help) echo $msg ; exit 1 ;;
    "") break ;;
    *) echo $msg ; exit 1 ;; 
    esac
done


if [[ -z "$local_dir" || -z "$dest_dir" ]]; then
	echo "param necessary, -l {local-dir} -d {dest-dir}"
	echo $msg
	exit 1
fi


############### create log directory ###############
if [[ ! -d "$path/log"]]; then
  mkdir -p $path/log
fi

ts=`date +%s`
log_file=${path}/log/sync.${ts}.log




############### generator to file ###############
if [[ -n "$ip_file" ]]; then
	if [[ -f "$ip_file" ]]; then
		cat $ip_file > ${path}/ip.rsync
	else
		echo $ip_file > ${path}/ip.rsync
	fi
elif [[ -n "$host_group" ]]; then
	#  get ips from hostgroup
	hosts=$(grep -i "$host_group" ${path}/conf/hostgroup | sed 's/"//g' | awk -F'=' '{print $2}')

	if [[ -z "$hosts" ]]; then
        	echo $1" not found"
	        exit 1
	fi
	echo $hosts | tr ' ' '\n' | grep -v '^$' > ${path}/ip.rsync
else
	echo $msg
	exit 1
fi


############### do rsync ###############
while read host
do
	echo "----------"${host}"---------" | tee -a $log_file
	rsync -rltvz -c --timeout=${t} --exclude-from="$path/exclude.list" ${local_dir} root@${host}:${dest_dir} | tee -a $log_file
	echo "----------------------------" | tee -a $log_file
done < ${path}/ip.rsync
