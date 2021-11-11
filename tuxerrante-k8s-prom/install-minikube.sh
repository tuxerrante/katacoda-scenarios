#/bin/bash
apt update
apt remove -y docker-ce*
apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils containerd
adduser `id -un` libvirtd
echo
echo 'GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"' > /etc/default/grub
update-grub
curl -sLO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
echo
echo "====== Starting minikube "
minikube start --kubernetes-version=v1.22.0  --feature-gates CoreDNS=true \
	--driver=kvm2 --container-runtime=containerd --delete-on-failure=true \
	--extra-config=kubelet.cgroup-driver=systemd --memory=1483mb --nodes 1 --force
echo
echo "====== Installing Prometheus operator 0.52"
curl -LO https://github.com/prometheus-operator/prometheus-operator/archive/refs/tags/v0.52.0.tar.gz
tar xzvf v0.52.0.tar.gz 
cd prometheus-operator-0.52.0
kubectl create -f bundle.yaml
echo "Enjoy breaking stuff!!"