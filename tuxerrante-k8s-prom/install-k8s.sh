#/bin/bash
apt update
apt install -y kubeadm=1.19.4-00 && \
	kubeadm config images pull --kubernetes-version 1.19.4 && \
	kubeadm upgrade apply v1.19.4 --yes 
apt install -y --allow-change-held-packages kubeadm=1.19.4-00 > /dev/null 2>&1
ssh node01 'apt install kubeadm=1.19.4-00 && kubeadm upgrade node'
# kubectl -n kube-system get cm kubeadm-config -oyaml
apt install -y kubelet=1.19.4-00 kubectl=1.19.4-00 > /dev/null 2>&
./launch.sh 