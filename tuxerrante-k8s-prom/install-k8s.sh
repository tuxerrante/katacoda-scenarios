#/bin/bash

kubeadm reset -y

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update >/dev/null 2>&1

apt-cache policy kubeadm |head
apt-get install -y kubelet=1.22.3-00 kubeadm=1.22.3-00 kubectl=1.22.3-00
apt-mark hold kubelet kubeadm kubectl

kubeadm init --pod-network-cidr=192.168.0.0/16

export TOKEN=$(kubeadm token list -o=jsonpath="{.token}")
export TOKEN_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
ssh node01 "apt update; apt install -y kubelet=1.22.3-00 kubeadm=1.22.3-00; kubeadm join --token ${TOKEN } controlplane:6443 --discovery-token-ca-cert-hash sha256:${TOKEN_HASH}" &

mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

export KUBECONFIG=/etc/kubernetes/admin.conf

curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml  >/dev/null



printf "=====> Waiting for cluster to start \n"
launch.sh 
kubectl get pods --all-namespaces
printf "=====> Updating worker node \n"

# kubectl -n kube-system get cm kubeadm-config -oyaml

./install-prom.sh
