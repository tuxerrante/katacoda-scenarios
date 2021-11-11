#/bin/bash
kubeadm reset -f >/dev/null

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo -e "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo -e "\n====="
apt-get update >/dev/null 2>&1
apt-cache policy kubeadm |head
apt-get install -y kubelet=1.22.3-00 kubeadm=1.22.3-00 kubectl=1.22.3-00 >/dev/null
apt-mark hold kubelet kubeadm kubectl

echo -e "\n====="
kubeadm init --pod-network-cidr=192.168.0.0/16

echo -e "\n=====> Updating worker node "
export TOKEN=$(kubeadm token list -o=jsonpath="{.token}")
export TOKEN_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

ssh node01 """
	apt-get install -y apt-transport-https ca-certificates curl >/dev/null
	apt-get update >/dev/null; \
	curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg; \
	echo -e 'deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list ; \
	apt-get install -y kubelet=1.22.3-00 kubeadm=1.22.3-00; kubeadm join --token ${TOKEN} controlplane:6443 --discovery-token-ca-cert-hash sha256:$TOKEN_HASH
	""" &

mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

curl https://docs.projectcalico.org/manifests/calico.yaml -O
kubectl apply -f calico.yaml  >/dev/null

echo -e "\n=====> Waiting for cluster to start "
launch.sh 

kubectl get pods --all-namespaces

# kubectl -n kube-system get cm kubeadm-config -oyaml

echo -e "\n====== Installing Prometheus operator 0.52 "
curl -sLO https://github.com/prometheus-operator/prometheus-operator/archive/refs/tags/v0.52.0.tar.gz
tar xzvf v0.52.0.tar.gz 
cd prometheus-operator-0.52.0
kubectl create -f bundle.yaml
echo -e "Enjoy breaking stuff!!\n"

