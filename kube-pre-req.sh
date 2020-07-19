#enable remote ssh login
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# disable firewalld
systemctl stop firewalld
systemctl disable firewalld
systemctl mask --now firewalld

#disable swap
swapoff -a 
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

#modify kernal params
modprobe br_netfilter

cat <<EOFK8S | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOFK8S

grep -q '^net.ipv4.ip_forward' /etc/sysctl.conf && sed -i  's/^net.ipv4.ip_forward*/net.ipv4.ip_forward=1/' /etc/sysctl.conf || echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sudo sysctl --system

#install docker
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker -y
systemctl start docker
systemctl enable docker


# install kubelet kubeadm amd kubectl
cat <<EOF1 | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF1

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
sudo systemctl enable --now kubelet
systemctl start kubelet


#modify hosts file
cat <<EOF2 >> /etc/hosts
192.168.56.121  master1.mykubecluster.com
192.168.56.122  master2.mykubecluster.com
192.168.56.123  master3.mykubecluster.com
192.168.56.124  node1.mykubecluster.com
192.168.56.125  node2.mykubecluster.com
192.168.56.126  kubeapi.mykubecluster.com
EOF2


#remove first lines in /etc/hosts
sed -i 1d /etc/hosts

#image pull - to save time later
kubeadm config images pull

#update and reboot

echo "yum install net-tools -y"  >> /tmp/update.sh
echo "yum install bind-utils -y"  >> /tmp/update.sh
echo "yum -y update" >> /tmp/update.sh

echo "reboot" >> /tmp/update.sh

chmod +x /tmp/update.sh

sleep 10


/tmp/update.sh &