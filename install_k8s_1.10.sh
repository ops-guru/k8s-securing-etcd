#!/bin/bash

yum update -y

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

yum install docker kubelet kubeadm kubectl -y
systemctl enable docker kubelet
systemctl start docker kubelet

sed s/SELINUX=enforcing/SELINUX=permissive/ /etc/selinux/config  -i
setenforce 0

grep KUBECONFIG /root/.bashrc || echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
export KUBECONFIG=/etc/kubernetes/admin.conf

cat <<EOF > kubeadmin_conf.yaml
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: $(kubeadm version -o short)
networking:
  podSubnet: 10.240.0.0/13
  serviceSubnet: 10.255.0.0/22
EOF

kubeadm init --config ./kubeadmin_conf.yaml --skip-preflight-checks
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
