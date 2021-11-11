#/bin/bash
apt update >/dev/null
apt install -y kubeadm=1.19.4-00 kubectl=1.19.4-00 && \
	kubeadm config images pull --kubernetes-version 1.19.4 /dev/null 2>&1
echo "=====> Waiting for cluster to start"
launch.sh 
echo "=====> Upgrading cluster to 1.19.4 "
kubeadm upgrade apply v1.19.4 --yes
# apt install -y --allow-change-held-packages kubeadm=1.19.4-00 > /dev/null 2>&1
echo "=====> Updatng worker node"
ssh node01 'apt update; apt install -y kubelet=1.19.3-00'
# kubectl -n kube-system get cm kubeadm-config -oyaml
apt install -y kubelet=1.19.4-00 kubectl=1.19.4-00 > /dev/null
kubeadm upgrade apply v1.20.12 --force
./install-prom.sh
