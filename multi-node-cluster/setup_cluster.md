

>>>>>>>>>>   **BELOW STEPS ARE FOR  SETTING UP ETCD**  <<<<<<<<<<<

**on primany master:**

```
{
curl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /usr/local/bin/cfssl
curl https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /usr/local/bin/cfssljson
chmod u+x /usr/local/bin/cfssl /usr/local/bin/cfssljson
yum -y install wget
}
```

Create the certificate authority configuration file:
```
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": ["signing", "key encipherment", "server auth", "client auth"],
        "expiry": "8760h"
      }
    }
  }
}
EOF
```

Create the certificate authority signing request configuration file:
```
{
cat > ca-csr.json <<EOF
{
  "CN": "Kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
  {
    "C": "IE",
    "L": "Cork",
    "O": "Kubernetes",
    "OU": "CA",
    "ST": "Cork Co."
  }
 ]
}
EOF
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
}
```

Creating the certificate for the Etcd cluster:
```
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
  {
    "C": "IE",
    "L": "Cork",
    "O": "Kubernetes",
    "OU": "Kubernetes",
    "ST": "Cork Co."
  }
 ]
}
EOF
```

```
cfssl gencert \
-ca=ca.pem \
-ca-key=ca-key.pem \
-config=ca-config.json \
-hostname=192.168.56.121,192.168.56.122,192.168.56.123,192.168.56.126,kubeapi.mykubecluster.com,127.0.0.1,kubernetes.default \
-profile=kubernetes kubernetes-csr.json | \
cfssljson -bare kubernetes
```

copy the certificates to all masters under temp:
```
scp ca.pem kubernetes.pem kubernetes-key.pem vagrant@192.168.56.121:/tmp/
scp ca.pem kubernetes.pem kubernetes-key.pem vagrant@192.168.56.122:/tmp/
scp ca.pem kubernetes.pem kubernetes-key.pem vagrant@192.168.56.123:/tmp/
```


**on all masters:**
Create directories:
```
{
sudo mkdir /etc/etcd /var/lib/etcd
mv /tmp/ca.pem /tmp/kubernetes.pem /tmp/kubernetes-key.pem /etc/etcd
}
```

Install ETCD:
```
{
yum -y install wget
wget https://github.com/etcd-io/etcd/releases/download/v3.3.13/etcd-v3.3.13-linux-amd64.tar.gz
tar xvzf etcd-v3.3.13-linux-amd64.tar.gz
sudo mv etcd-v3.3.13-linux-amd64/etcd* /usr/local/bin/
}
```

setup etcd service:
```
{
ETCD_NAME=$(hostname -f)
INTERNAL_IP=$(ifconfig eth1 | awk '/inet / {print $2}')
INITIAL_CLUSTER=master1.mykubecluster.com=https://192.168.56.121:2380,master2.mykubecluster.com=https://192.168.56.122:2380,master3.mykubecluster.com=https://192.168.56.123:2380

cat << EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster ${INITIAL_CLUSTER} \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
}
```

restart ETCD:
```
{
sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl restart etcd    
}
```

check health:
```
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
```

>>>>>>>>>>  **ETCD SETUP IS DONE**  ^^^^^^^^^^^

</br>
</br>

>>>>>>>>>> **CONTROL PLANE and NODE  SETUP**


**ON Master 1:**
```
{
export MASTER_1_IP=172.31.32.46
export MASTER_2_IP=172.31.44.223
export MASTER_3_IP=172.31.46.229
export API_SERVER_DNS=rajm86c.mylabserver.com

cat << EOF | sudo tee config.yaml
apiVersion: kubeadm.k8s.io/v1beta2
kind: ClusterConfiguration
kubernetesVersion: stable
apiServerCertSANs:
- kubeapi.mykubecluster.com
controlPlaneEndpoint: "kubeapi.mykubecluster.com:6443"
etcd:
  external:
    endpoints:
    - https://192.168.56.121:2379
    - https://192.168.56.122:2379
    - https://192.168.56.123:2379
    caFile: /etc/etcd/ca.pem
    certFile: /etc/etcd/kubernetes.pem
    keyFile: /etc/etcd/kubernetes-key.pem
networking:
  podSubnet: 10.30.0.0/24
apiServerExtraArgs:
  apiserver-count: "3"
apiServer:
  extraArgs:
    advertise-address: 192.168.56.121
EOF
}
```


**option 1** ( by using ```--upload-certs``` ): we are not using option: 2 i.e. without ```--upload-certs```  in that case ( option: 2) we need to manually copy all certs from 1st master to other masters.


```
kubeadm init --control-plane-endpoint "kubeapi.mykubecluster.com:6443" --upload-certs --apiserver-advertise-address 192.168.56.121
```

the above command prints steps for on how to export kubeconfig and  the node and master join commands. 

</br>
Apply CNI of your choice or below:

```
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl get pod -n kube-system -w
```


**on remaning masters and nodes:**

now add other masters and nodes using join commands that you get from above ```kubeadm init xxx``` command.


incase if you not saved/lost your command ``` kubeadm token create --print-join-command ``` 


>>>>>>>>>> **CONTROL PLANE and NODE  SETUP IS DONE**

</br>
</br>

>>>>>>>>>> **DEPLOY DASHBOARD AND A TEST APP**


**Deploy Dashboard: run on master-1**

```
{
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
}
```


```
{
cat <<EOF4 >> cdashboard-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
EOF4
kubectl apply -f cdashboard-sa.yaml
}
```

```
{
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
}
```



**a) To access the dashboard:**

```
https://192.168.56.121:30007/
```

To get the token that required for dashboard:

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```



**b) Deploy sample app:**

login into cluster using 1)

```
{
kubectl create namespace nginx-example
cat <<EOF4 >> nginx-app.yaml
apiVersion: apps/v1 # for versions before 1.9.0 use apps/v1beta2
kind: Deployment
metadata: 
  name: nginx-deployment
  namespace: nginx-example
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 # tells deployment to run 2 pods matching the template
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
EOF4
kubectl create -f nginx-app.yaml
cat <<EOF3 >> nginx-app-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: nginx-example
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30009
EOF3
kubectl create -f nginx-app-service.yaml
}
```

access the application at:  ```http://<any-node-ip>:30009```


Ex.
```
http://192.168.56.122:30009/
```











