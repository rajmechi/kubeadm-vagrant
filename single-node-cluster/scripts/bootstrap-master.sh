
#install cfssl


#image pull - to save time later
kubeadm config images pull

kubeadm init --control-plane-endpoint "master1.mykubecluster.com:6443" --pod-network-cidr=10.244.0.0/16  --apiserver-advertise-address 192.168.56.121


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config


#apply CNI
kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml

sleep 5

kubeadm token create --print-join-command >> /etc/kubeadm_join_cmd.sh
chmod +x /etc/kubeadm_join_cmd.sh

sleep 3

#deploy dashboard

kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml
cat <<EOF3 >> create-new-dashboard-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-dashboard
  namespace: kubernetes-dashboard
spec:
  type: NodePort
  selector:
    k8s-app: kubernetes-dashboard
  ports:
    - port: 443
      targetPort: 8443
      nodePort: 30007
EOF3
kubectl create -f create-new-dashboard-service.yaml


cat <<EOF4 >> cdashboard-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
EOF4
kubectl apply -f cdashboard-sa.yaml


cat <<EOF5 >> cdashboard-rb.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system
EOF5
kubectl apply -f cdashboard-rb.yaml
