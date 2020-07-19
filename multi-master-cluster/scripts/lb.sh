#enable remote ssh login
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
systemctl restart sshd

# disable firewalld
systemctl stop firewalld
systemctl disable firewalld
systemctl mask --now firewalld



yum -y install haproxy



cat <<EOF >> /etc/haproxy/haproxy.cfg
frontend kubernetes
    bind *:6443
    option tcplog
    mode tcp
    default_backend kubernetes-master-nodes
backend kubernetes-master-nodes
    mode tcp
    balance roundrobin
    option tcp-check
    server k8s-master-0 192.168.56.121:6443 check
    server k8s-master-1 192.168.56.122:6443 check
    server k8s-master-2 192.168.56.123:6443 check
EOF

setsebool -P haproxy_connect_any=1
systemctl restart haproxy
