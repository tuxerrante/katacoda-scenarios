echo "====== Installing Prometheus operator 0.52"
curl -LO https://github.com/prometheus-operator/prometheus-operator/archive/refs/tags/v0.52.0.tar.gz
tar xzvf v0.52.0.tar.gz 
cd prometheus-operator-0.52.0
kubectl create -f bundle.yaml
echo "Enjoy breaking stuff!!"
