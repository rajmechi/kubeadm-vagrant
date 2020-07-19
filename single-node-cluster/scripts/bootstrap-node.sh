


yum install sshpass -y
sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.56.121:/etc/kubeadm_join_cmd.sh .
sh ./kubeadm_join_cmd.sh