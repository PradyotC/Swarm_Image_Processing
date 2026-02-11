#!/bin/bash
# 1. UPDATE & INSTALL ESSENTIALS
# Headless JRE is used to minimize disk and RAM usage
dnf update -y
dnf install java-21-amazon-corretto-headless git ImageMagick -y

# 2. CREATE 2GB SWAP
# Vital for t3.micro agents to handle parallel image processing without crashing
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab

# 3. CONFIGURE PERSISTENT WORKSPACES
# We create dedicated directories on the disk to avoid the 1GB RAM-based /tmp limit
mkdir -p /home/ec2-user/jenkins_agent
mkdir -p /home/ec2-user/jenkins_tmp
chown -R ec2-user:ec2-user /home/ec2-user/jenkins_agent
chown -R ec2-user:ec2-user /home/ec2-user/jenkins_tmp

# 4. (Optional) Create a completion marker
echo "Slave Node Ready" > /home/ec2-user/setup_complete.txt
