

my vm's:

| IP              |       fqdn                 |
| -------------   | -------------------------  |
| 192.168.56.121  | master1.mykubecluster.com  |
| 192.168.56.122  | node1.mykubecluster.com    |
| 192.168.56.123  | node2.mykubecluster.com    |


**you can control number of nodes using ```N=2``` in Vagrantfile


**1) To deploy the cluster:**


```
vagrant up
```




**2) To access the master & to run oc commands:**

```
vagrant ssh master-1
sudo bash
```

or 

ssh using putty to ```192.168.56.121``` as user: ```vagrant``` password: ```vagrant```


</br>



**3) To access the dashboard:**

```
https://192.168.56.121:30007/
```

To get the token that required for dashboard:

```
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')
```


**4) Deploy sample app:**

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