sudo su -
sed -i 's/^#Port 22$/Port 50011/' /etc/ssh/sshd_config && systemctl restart sshd