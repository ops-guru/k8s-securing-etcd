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

yum install docker kubelet-1.9.3 kubeadm-1.9.3 kubectl-1.9.3 -y
systemctl enable docker kubelet
systemctl start docker kubelet

sed s/SELINUX=enforcing/SELINUX=permissive/ /etc/selinux/config  -i
setenforce 0

grep KUBECONFIG /root/.bashrc || echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /root/.bashrc
export KUBECONFIG=/etc/kubernetes/admin.conf

cat <<EOF > /etc/kubernetes/manifests/etcd.yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd-tls
  namespace: kube-system
spec:
  hostNetwork: true
  containers:
  - name: etcd
    command:
    - etcd
    - --name=\$(NODE_NAME)
    - --data-dir=/var/lib/etcd/
    - --wal-dir=/var/lib/etcd/wal/
    - --listen-peer-urls=https://0.0.0.0:7001
    - --listen-client-urls=https://0.0.0.0:2379
    - --advertise-client-urls=https://\$(NODE_NAME):2379
    - --initial-advertise-peer-urls=https://\$(NODE_NAME):7001
    - --initial-cluster=\$(NODE_NAME)=https://\$(NODE_NAME):7001
    - --initial-cluster-state=new
    - --client-cert-auth=true
    - --peer-client-cert-auth=true
    - --peer-auto-tls=true
    - --trusted-ca-file=/etc/kubernetes/pki/ca.crt
    - --cert-file=/etc/kubernetes/pki/apiserver.crt
    - --key-file=/etc/kubernetes/pki/apiserver.key
    image: gcr.io/google_containers/etcd-amd64:3.0.17
    env:
    - name: NODE_NAME
      valueFrom:
        fieldRef:
          fieldPath: spec.nodeName
    livenessProbe:
      failureThreshold: 8
      tcpSocket:
        port: 2379
      initialDelaySeconds: 15
      timeoutSeconds: 15
    volumeMounts:
    - mountPath: /var/lib/etcd
      name: etcd
    - mountPath: /etc/kubernetes/
      name: k8s
      readOnly: true
  securityContext:
    seLinuxOptions:
      type: spc_t
  volumes:
  - hostPath:
      path: /var/lib/etcd
    name: etcd
  - hostPath:
      path: /etc/kubernetes
    name: k8s
EOF

cat <<EOF > kubeadmin_conf.yaml
apiVersion: kubeadm.k8s.io/v1alpha1
kind: MasterConfiguration
kubernetesVersion: $(kubeadm version -o short)
networking:
  podSubnet: 10.240.0.0/13
  serviceSubnet: 10.255.0.0/22
etcd:
  endpoints:
  - https://$HOSTNAME:2379
  caFile: /etc/kubernetes/pki/ca.crt
  certFile: /etc/kubernetes/pki/apiserver-kubelet-client.crt
  keyFile: /etc/kubernetes/pki/apiserver-kubelet-client.key
EOF

kubeadm init --config ./kubeadmin_conf.yaml --skip-preflight-checks
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.10.0/Documentation/kube-flannel.yml
