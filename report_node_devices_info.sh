#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`

source $Deploy_Path/ceph_cluster.env

if [ ! -d device_info ];then
    mkdir device_info
fi

rm -f device_info/*
for i in $Ceph_Hostnames;do
{
    ssh $i "lsblk && lsscsi -l && ls -l /dev/disk/by-path/ && lspci && lscpu \
	    && ether=\`lspci|grep Ether|awk '{print \$1}'\` \
	    && for i in \$ether;do ether_map=\`ls -l /sys/class/net/ |grep -w \$i\`;ether_name=\`ls -l /sys/class/net/ |grep -w \$i|awk '{print \$9}'\`;ether_speed=\`cat /sys/class/net/\$ether_name/speed\`;echo \$ether_map \$ether_speed;done " > $Deploy_Path/device_info/$i-`date "+%Y-%m-%d-%H-%M-%S"`-devices.info
}&
done
wait



