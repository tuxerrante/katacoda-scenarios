#/bin/bash

apt update
apt upgrade -y docker-ce*

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

echo
echo "====== Starting minikube "
minikube start --kubernetes-version=v1.21.0  --feature-gates CoreDNS=true --container-runtime=docker --delete-on-failure=true --extra-config=kubelet.cgroup-driver=systemd --memory=2200mb --nodes 2

echo
echo "====== Installing Prometheus operator 0.52"
curl -LO https://github.com/prometheus-operator/prometheus-operator/archive/refs/tags/v0.52.0.tar.gz
tar xzvf v0.52.0.tar.gz 
cd prometheus-operator-0.52.0
kubectl create -f bundle.yaml

echo "Enjoy breaking stuff!!"