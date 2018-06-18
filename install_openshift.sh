#!/bin/bash

yum -y install centos-release-openshift-origin
yum -y install atomic-openshift-utils origin-clients docker
sed "s#^\(OPTIONS=.*\)'#\1 --insecure-registry 172.30.0.0/16'#" /etc/sysconfig/docker -i

systemctl enable docker
systemctl start docker

oc cluster up --host-data-dir /var/lib/origin/openshift.local.etcd --use-existing-config=true
