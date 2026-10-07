# -*- mode: ruby -*-
# vi: set ft=ruby :

# ==============================================================================
# Kubernetes Cluster Lab via Vagrant & VirtualBox
# 1 Control-Plane Node + 3 Worker Nodes
# Disimpan di External Disk (D:\VirtualBox VMs)
# ==============================================================================

VAGRANTFILE_API_VERSION = "2"

IMAGE_NAME = "bento/ubuntu-22.04"
WORKER_COUNT = 3

CONTROL_PLANE_CPU = 2
CONTROL_PLANE_MEMORY = 2048

WORKER_CPU = 1
WORKER_MEMORY = 1536

NETWORK_PREFIX = "192.168.56."
CONTROL_PLANE_IP = "#{NETWORK_PREFIX}10"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Base Box OS
  config.vm.box = IMAGE_NAME

  # Folder bersama untuk token join & kubeconfig
  config.vm.synced_folder "./shared", "/vagrant/shared", create: true

  # ----------------------------------------------------------------------------
  # Control Plane (Master Node)
  # ----------------------------------------------------------------------------
  config.vm.define "k8s-control-plane" do |master|
    master.vm.hostname = "k8s-control-plane"
    master.vm.network "private_network", ip: CONTROL_PLANE_IP

    master.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-control-plane"
      vb.cpus = CONTROL_PLANE_CPU
      vb.memory = CONTROL_PLANE_MEMORY
      vb.customize ["modifyvm", :id, "--audio", "none"]
    end

    master.vm.provision "shell", path: "scripts/common.sh", args: [CONTROL_PLANE_IP], binary: true
    master.vm.provision "shell", path: "scripts/control-plane.sh", binary: true
  end

  # ----------------------------------------------------------------------------
  # Worker Nodes (k8s-worker-1 s/d k8s-worker-3)
  # ----------------------------------------------------------------------------
  (1..WORKER_COUNT).each do |i|
    worker_name = "k8s-worker-#{i}"
    worker_ip = "#{NETWORK_PREFIX}#{10 + i}"

    config.vm.define worker_name do |worker|
      worker.vm.hostname = worker_name
      worker.vm.network "private_network", ip: worker_ip

      worker.vm.provider "virtualbox" do |vb|
        vb.name = worker_name
        vb.cpus = WORKER_CPU
        vb.memory = WORKER_MEMORY
        vb.customize ["modifyvm", :id, "--audio", "none"]
      end

      worker.vm.provision "shell", path: "scripts/common.sh", args: [worker_ip], binary: true
      worker.vm.provision "shell", path: "scripts/worker.sh", binary: true
    end
  end
end
