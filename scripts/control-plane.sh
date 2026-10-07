#!/bin/bash
set -euxo pipefail

CONTROL_PLANE_IP="192.168.56.10"
POD_CIDR="10.244.0.0/16"

# 1. Inisialisasi Kubernetes Control Plane
echo "=== Memulai kubeadm init ==="
kubeadm init \
  --apiserver-advertise-address="${CONTROL_PLANE_IP}" \
  --pod-network-cidr="${POD_CIDR}" \
  --node-name=k8s-control-plane

# 2. Konfigurasi kubeconfig untuk user vagrant
mkdir -p /home/vagrant/.kube
cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
chown vagrant:vagrant /home/vagrant/.kube/config

# Konfigurasi kubeconfig untuk user root
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config

# 3. Salin kubeconfig ke shared folder agar bisa diakses dari host
mkdir -p /vagrant/shared
cp -f /etc/kubernetes/admin.conf /vagrant/shared/kubeconfig
chmod 644 /vagrant/shared/kubeconfig

# 4. Terapkan Flannel CNI
echo "=== Memasang Flannel CNI ==="
su - vagrant -c "kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"

# 5. Buat skrip join untuk worker nodes
echo "=== Menghasilkan skrip join worker ==="
kubeadm token create --print-join-command > /vagrant/shared/join.sh
chmod +x /vagrant/shared/join.sh

echo "=== Control Plane Berhasil Dikonfigurasi ==="
