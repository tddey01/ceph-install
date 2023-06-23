#!/bin/bash
Deploy_Path=`cd $(dirname $0); pwd -P`
rm -rf openstack/*
rm -f ceph-openstack.tar.gz
mkdir -p openstack/config/glance
mkdir -p openstack/config/cinder/{cinder-volume,cinder-backup}
mkdir -p openstack/config/nova
mkdir -p openstack/config/gnocchi
ceph osd pool create volumes 256 256
ceph osd pool create images 128 128
ceph osd pool create backups 128 128
ceph osd pool create vms 256 256
ceph osd pool create metrics 256 256

rbd pool init volumes
rbd pool init images
rbd pool init backups
rbd pool init vms

ceph auth get-or-create client.glance mon 'profile rbd' osd 'profile rbd pool=images' mgr 'profile rbd pool=images'
ceph auth get-or-create client.cinder mon 'profile rbd' osd 'profile rbd pool=volumes, profile rbd pool=vms, profile rbd-read-only pool=images' mgr 'profile rbd pool=volumes, profile rbd pool=vms'
ceph auth get-or-create client.cinder-backup mon 'profile rbd' osd 'profile rbd pool=backups' mgr 'profile rbd pool=backups'
ceph auth get-or-create client.gnocchi mon "allow r" osd "allow rwx pool=metrics"

ceph auth get-or-create client.glance |tee openstack/config/glance/ceph.client.glance.keyring
ceph auth get-or-create client.cinder | tee openstack/config/cinder/cinder-volume/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder-backup | tee openstack/config/cinder/cinder-backup/ceph.client.cinder-backup.keyring
ceph auth get-or-create client.cinder | tee openstack/config/cinder/cinder-backup/ceph.client.cinder.keyring
ceph auth get-or-create client.cinder | tee openstack/config/nova/ceph.client.cinder.keyring
ceph auth get-or-create client.gnocchi |tee openstack/config/gnocchi/ceph.client.gnocchi.keyring
cp $Deploy_Path/conf/ceph.conf.rbd  openstack/config/glance/ceph.conf
cp $Deploy_Path/conf/ceph.conf.rbd  openstack/config/cinder/cinder-volume/ceph.conf
cp $Deploy_Path/conf/ceph.conf.rbd  openstack/config/cinder/cinder-backup/ceph.conf
cp $Deploy_Path/conf/ceph.conf.rbd  openstack/config/nova/ceph.conf
cp $Deploy_Path/conf/ceph.conf.rbd  openstack/config/gnocchi/ceph.conf

tar cvf ceph-openstack.tar.gz openstack
