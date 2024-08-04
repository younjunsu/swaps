#!/bin/bash
keyword=$1

function help_shell(){
    echo "-----------------------------"
    echo "Swap Memory Usage Script"
    echo "-----------------------------"
    echo "$ ./swaps.sh %s"
    echo "%s: all"
    echo "%s: keyword"
    echo "-----------------------------"
}

function all_type(){
    export proc_pid_list=$(ps -ef |awk '$2!=2 && $3!=2' |awk '{print $2}')
    export proc_pid_name=$(ps -ef |awk '$2!=2 && $3!=2' |awk '{print $2" "$8}')    
}

function keyword_type(){
    export proc_pid_list=$(ps -ef |awk '$2!=2 && $3!=2' |grep $keyword |awk -v current_user="${current_user}" '$1==current_user' |awk '{print $2}')
    export proc_pid_name=$(ps -ef |awk '$2!=2 && $3!=2' |grep $keyword |awk -v current_user="${current_user}" '$1==current_user' |awk '{print $2" "$8}')
}

function non_shared_memory_swap(){
    non_shared_memroy_total=0
    echo "###############################################################"
    echo " Non-Shared Memory Swap Total"
    echo "###############################################################"
    for proc_pid in ${proc_pid_list[@]}
    do
        smaps_file_check=`ls /proc/$proc_pid/smaps 2>/dev/null` 
        if [ -n "$smaps_file_check" ]
        then
            proc_swap_sum=`grep -E "Swap:|rw|r-|--"  /proc/$proc_pid/smaps |sed '/SYSV/{N;d;}' |grep "Swap:" |awk '{sum += $2} END {print sum}'`
            proc_swap_percent=`awk "BEGIN {printf \"%.2f\n\", $proc_swap_sum / $os_swap_total * 100}"`
            printf "%-10s %-40s %-30s %-30s\n" "$proc_pid" "$(echo "$proc_pid_name" | awk -v proc_pid="${proc_pid}" '$1==proc_pid' | awk '{print $2}')" "$proc_swap_sum KB" "($proc_swap_percent%)"
            proc_swap_sum=`echo $proc_swap_sum |awk '{print $1}'`
            non_shared_memroy_total=`echo "$non_shared_memroy_total" + "$proc_swap_sum" |bc`
        fi
    done
    echo "--------------------------------------------------------"
    non_shared_memory_swap_percent=`awk "BEGIN {printf \"%.2f\n\", $non_shared_memroy_total / $os_swap_total * 100}"`
    echo "Swap Total : $non_shared_memroy_total KB ( "$non_shared_memory_swap_percent"% )"
    echo "--------------------------------------------------------"
}

function shared_memory_swap(){
    shared_memory_total=0
    echo "###############################################################"
    echo " Shared Memory Swap Total"
    echo "###############################################################"
    shmid_list=$(ipcs -m |grep -vE "key        shmid|Shared Memory|^$" |awk '{print $2}')
    ipcs -m
    for shmid in ${shmid_list}
    do
        shmid_swap_byte=`cat /proc/sysvipc/shm |awk -v shmid="${shmid}" '$2==shmid'|awk '{print $NF}'`
        shmid_swap=`echo "$shmid_swap_byte / 1024" |bc`
        shmid_swap_percent=`awk "BEGIN {printf \"%.2f\n\", $shmid_swap / $os_swap_total * 100}"`
        echo "Shared Memory ID: $shmid Swap Usage: $shmid_swap KB ( "$shmid_swap_percent"% )"
        echo "--------------------------------------------------------"
    done
}

function os_memory(){
    echo "###############################################################"
    echo " Memory"
    echo "###############################################################"
    free -k

    os_swap_total=`grep "SwapTotal" /proc/meminfo |awk '{print $2}'`
    os_swap_free=`grep "SwapFree" /proc/meminfo |awk '{print $2}'`
    os_swap_cache=`grep "SwapCached" /proc/meminfo |awk '{print $2}'`
    os_swap_used=`echo "$os_swap_total - $os_swap_free + $os_swap_cache" |bc`
    os_swap_used_percent=`awk "BEGIN {printf \"%.2f\n\", $os_swap_used / $os_swap_total * 100}"`
    echo "OS Swap Used Percent : $os_swap_used_percent%"
}

export current_user=`whoami`
export os_swap_total=`grep "SwapTotal" /proc/meminfo |awk '{print $2}'`

if [ "all" == "$keyword" ]
then
    if [ "root" == "$current_user" ]
    then
        all_type
        non_shared_memory_swap
        shared_memory_swap    
        os_memory
    else
        echo ""all type" must be run as root user."
    fi
elif [ -n "$keyword" ]
then
    keyword_type
    non_shared_memory_swap
    shared_memory_swap
    os_memory
elif [ -z "$keyword" ]
then
    help_shell
else
    help_shell
fi
