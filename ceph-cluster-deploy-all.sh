#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`
#Ceph_Nodes=`cat /etc/hosts|egrep -v "^$|^#"|grep ceph|awk '{print $1}'`
source $Deploy_Path/ceph_cluster.env

for i in $Ceph_Nodes;do
{
    ssh -p $ssh_port -l root -t $i "nohup bash -x $Deploy_Path/deploy-ceph-on-localnode.sh >> $Deploy_Path/logs/ceph-deploy-`date +'%Y-%m-%d-%H-%M-%S'`.log  2>&1 &"
}&
done 
wait

