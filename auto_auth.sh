#!/bin/bash
Deploy_Path=`cd $(dirname $0);pwd -P`
source $Deploy_Path/ceph_cluster.env

Names=$(cat conf/hosts|grep $Cluster_Domain|grep mgmt|awk '{print $1, $2}'|tr -s "\r\n" " ")
for a in $Names;do {
     sshpass -p $ROOT_PASSWD ssh -p $ssh_port -l root -o stricthostkeychecking=no $a "echo `hostname` to $a Authentication Succeeded!"
}&
wait
done


