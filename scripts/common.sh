#!/bin/bash
set -euxo pipefail

NODE_IP="${1:-}"

# 1. Nonaktifkan swap
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# 2. Muat kernel module untuk jaringan Kubernetes
cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# 3. Konfigurasi sysctl untuk iptables & ip forwarding
cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

# 4. Instal containerd runtime dari repository Docker
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https conntrack ebtables ethtool socat iptables iproute2

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y containerd.io

# Konfigurasi containerd dengan SystemdCgroup = true
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml > /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd

# 5. Instal kubeadm, kubelet, dan kubectl (Repository Resmi Kubernetes pkgs.k8s.io v1.31)
K8S_VERSION="v1.31"
curl -fsSL "https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/Release.key" | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg --yes
chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/${K8S_VERSION}/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl

# 6. Konfigurasi IP internal kubelet
if [ -n "${NODE_IP}" ]; then
  echo "KUBELET_EXTRA_ARGS=--node-ip=${NODE_IP}" > /etc/default/kubelet
  systemctl daemon-reload
  systemctl restart kubelet
fi

# 7. Pemetaan Hostname (/etc/hosts)
sed -i '/k8s-/d' /etc/hosts
cat >> /etc/hosts <<EOF
192.168.56.10 k8s-control-plane
192.168.56.11 k8s-worker-1
192.168.56.12 k8s-worker-2
192.168.56.13 k8s-worker-3
EOF
