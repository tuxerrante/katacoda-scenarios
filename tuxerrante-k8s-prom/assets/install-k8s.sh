#/bin/bash
echo

curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo
echo "===== Installing kubeadm and friends.."
apt-get update --allow-unauthenticated >/dev/null 2>&1 || true
apt-get install -y --install-recommends kubeadm=1.22.3-00 >/dev/null 2>&1 || true

echo "===== Deleting previous environment.. "
kubeadm reset -f >/dev/null 2>&1
rm -rf /etc/kubernetes/*

echo
echo "====="
rm -rf /etc/kubernetes/manifests/* /var/lib/etcd/*
kubeadm init --pod-network-cidr=192.168.0.0/16

echo
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
export KUBECONFIG=/etc/kubernetes/admin.conf

launch.sh 
kubeadm upgrade apply v1.22.3 --force

echo "=====> Updating worker node "
export TOKEN=$(kubeadm token list -o=jsonpath="{.token}")
export TOKEN_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
export CONTROLPLANE_IP=$(hostname -I |cut -f1 -d" ")

echo
cat <<EOF >/root/worker-init.sh
	apt-get install -y apt-transport-https ca-certificates curl >/dev/null;
	curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg; 
	echo 'deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list ; 
	apt-get update --allow-unauthenticated >/dev/null; 
	apt-get install -y kubelet=1.22.3-00 kubeadm=1.22.3-00; 
	kubeadm join --token ${TOKEN} ${CONTROLPLANE_IP}:6443 --discovery-token-ca-cert-hash sha256:${TOKEN_HASH}
EOF
chmod +x /root/worker-init.sh

ssh node01 bash <"/root/worker-init.sh" >/var/log/worker-init.log 2>&1 &

echo "=====>  CALICO "
curl -sLO https://docs.projectcalico.org/manifests/calico.yaml
kubectl apply -f calico.yaml  >/dev/null

echo "=====> Waiting for cluster to start "
launch.sh 
kubectl get pods --all-namespaces

echo "=====> Installing Prometheus operator 0.52 "
curl -sLO https://github.com/prometheus-operator/prometheus-operator/archive/refs/tags/v0.52.0.tar.gz
tar xzvf v0.52.0.tar.gz >/dev/null
cd prometheus-operator-0.52.0
kubectl create -f bundle.yaml >/dev/null

echo "Enjoy breaking stuff!"
kubectl get nodes -o wide
watch kubectl get pods -A 
