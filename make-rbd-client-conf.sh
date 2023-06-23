#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`

source $Deploy_Path/ceph_cluster.env

FSID=`sed -n "/^fsid.*/"p $Deploy_Path/conf/ceph.conf |awk '{print $NF}'`

#创建ceph.conf.rbd配置文件
echo '[global]' >  $Deploy_Path/conf/ceph.conf.rbd
echo "fsid = $FSID" >> $Deploy_Path/conf/ceph.conf.rbd
MON_HOSTS=$(echo $MON_Nodes|sed 's/[ ]/,/g')
echo "public_network = $Public_CIDR" >> $Deploy_Path/conf/ceph.conf.rbd
echo "cluster_network = $Cluster_CIDR" >> $Deploy_Path/conf/ceph.conf.rbd
echo "mon_host = $MON_HOSTS" >> $Deploy_Path/conf/ceph.conf.rbd
echo "auth_cluster_required = cephx" >> $Deploy_Path/conf/ceph.conf.rbd
echo "auth_service_required = cephx" >> $Deploy_Path/conf/ceph.conf.rbd
echo "auth_client_required = cephx" >> $Deploy_Path/conf/ceph.conf.rbd

