
**Multi master and nod setup is not fully automated. require some manual steps.

my vm's:

| IP              |       fqdn                 |
| -------------   | -------------------------  |
| 192.168.56.121  | master1.mykubecluster.com  |
| 192.168.56.122  | master2.mykubecluster.com  |
| 192.168.56.123  | master3.mykubecluster.com  |
| 192.168.56.124  | node1.mykubecluster.com    |
| 192.168.56.125  | node2.mykubecluster.com    |
| 192.168.56.126  | kubeapi.mykubecluster.com  |



How to deploy the cluster:


step 1:  in this folder ```vagrant up```
</br>
step2: then follow [Setup ETCD, bootstrap cluster and deploy  dashboard and sample app](setup_cluster.md)


**here followed External ETCD model. i.e. deploying ETCD manually and providing ETCD info for kubeadm (step 2:). but we are using same master nodes for ETCD deployment.