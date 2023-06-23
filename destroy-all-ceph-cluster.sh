#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`
source $Deploy_Path/ceph_cluster.env

for i in $Ceph_Nodes;do
   {
    ssh -p $ssh_port -t -l root $i "bash $Deploy_Path/destroy-ceph-on-localnode.sh "
   }&
done
wait
