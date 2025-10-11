#!/bin/bash

install_ubuntu() {

   #### Install Kubernetes v1.34 components
   sudo apt-get update
   sudo apt-get install -y apt-transport-https ca-certificates curl gpg

   echo "Starting the installation of Kubernetes v1.34 components (kubeadm, kubelet, kubectl)..."

   # Add Kubernetes GPG key and repo
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
   echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

   sudo apt-get update

   # Install specific version (latest from v1.34 line) or just install without version
   sudo apt-get install -y kubelet kubeadm kubectl

   if [ $? -eq 0 ]; then
      echo "kubelet, kubeadm & kubectl are successfully installed"
      sudo apt-mark hold kubelet kubeadm kubectl
   else
      echo "Issue in installing kubelet, kubeadm & kubectl - process aborted"
      exit 2
   fi
}

install_centos() {

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

if [ $? -eq 0 ]; then
   echo "kubelet, kubeadm & kubectl are successfully installed"
   sudo systemctl enable --now kubelet
else
   echo "Issue in installing kubelet, kubeadm & kubectl - process aborted"
   exit 2
fi
}

install_amzn() {

cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

if [ $? -eq 0 ]; then
   echo "kubelet, kubeadm & kubectl are successfully installed"
   sudo systemctl enable --now kubelet
else
   echo "Issue in installing kubelet, kubeadm & kubectl - process aborted"
   exit 2
fi
}

################ MAIN ###################

if [ -f /etc/os-release ]; then
   osname=$(grep ^ID= /etc/os-release | cut -d'=' -f2 | tr -d '"')
   echo "Detected OS: $osname"

   case "$osname" in
       ubuntu)
           install_ubuntu
           ;;
       amzn)
           install_amzn
           ;;
       centos)
           install_centos
           ;;
       *)
           echo "Unsupported OS: $osname"
           exit 7
           ;;
   esac
else
   echo "Cannot locate /etc/os-release - unable to determine OS."
   exit 8
fi

exit 0
