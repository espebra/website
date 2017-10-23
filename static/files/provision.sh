# Delete account passwords
/bin/passwd -d root
/bin/passwd -d ansible

# Lock the root account for login
/sbin/usermod -L root

# Tighten sshd a bit
sed s/PasswordAuthentication\ yes/PasswordAuthentication\ no/ -i /etc/ssh/sshd_config
sed s/GSSAPIAuthentication\ yes/GSSAPIAuthentication\ no/ -i /etc/ssh/sshd_config
sed s/ChallengeResponseAuthentication\ yes/ChallengeResponseAuthentication\ no/ -i /etc/ssh/sshd_config

cat >> /etc/ssh/sshd_config <<EOF
PermitRootLogin no
EOF

# Reset ssh host keys
rm -f /etc/ssh/ssh_host_*key*
