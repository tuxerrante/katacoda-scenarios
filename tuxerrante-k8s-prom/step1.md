
## Start here
`chmod +x ./install-k8s.sh && sh ./install-k8s.sh`{{execute}}  
Press CTRL+C to start working after the pods are UP.  

### Monitor the status
`kubectl get nodes -o wide`{{execute}}  
`watch kubectl get pods -A`{{execute}}  
