#!/bin/bash
# 1. UPDATE & INSTALL ESSENTIALS
dnf update -y
dnf install git wget ImageMagick -y

# 2. CREATE 4GB SWAP (Crucial for 1GB RAM stability)
# This prevents Jenkins from crashing during peak orchestration
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# 3. INSTALL JAVA 21 (Headless)
# Headless saves disk space and RAM by removing GUI libraries
dnf install java-21-amazon-corretto-headless -y

# 4. INSTALL JENKINS
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install jenkins -y

# 5. PREPARE STORAGE FOR SWARM PROJECT
# Moving temp to disk prevents the "1GB threshold" error caused by RAM-based /tmp
mkdir -p /var/lib/jenkins/new_tmp
mkdir -p /var/lib/jenkins/userContent
chown -R jenkins:jenkins /var/lib/jenkins/new_tmp
chown -R jenkins:jenkins /var/lib/jenkins/userContent

# 6. CONFIGURE MEMORY LIMITS & SYSTEMD
# We cap Java at 512MB to leave 400MB+ for the OS kernel
sed -i 's|^Environment="JAVA_OPTS=.*|Environment="JAVA_OPTS=-Djava.awt.headless=true -Xmx512m -Xms512m -XX:+UseSerialGC -Djava.io.tmpdir=/var/lib/jenkins/new_tmp"|' /usr/lib/systemd/system/jenkins.service

# 7. SSH SETUP (FOR MANUAL NODE CONNECTION)
# Keeping keys in the default location for easy manual setup as requested
ssh-keygen -t ed25519 -N "" -f /root/.ssh/id_ed25519 <<< y >/dev/null 2>&1

# 8. START JENKINS
systemctl daemon-reload
systemctl enable jenkins
systemctl start jenkins

echo "Jenkins Setup Complete" > /home/ec2-user/setup_complete.txt
