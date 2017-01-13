#!/bin/bash -e

sudo yum upgrade --assumeyes --tolerant
sudo yum update --assumeyes
sudo yum -y update
sudo tee /etc/yum.repos.d/docker.repo <<-EOF
[dockerrepo]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
EOF

sudo tee /etc/modules-load.d/overlay.conf <<-EOF
overlay
EOF
sudo modprobe overlay
sudo mkdir -p /etc/systemd/system/docker.service.d && sudo tee /etc/systemd/system/docker.service.d/override.conf <<-EOF
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --storage-driver=overlay
EOF
sudo chmod -w /etc/systemd/system/docker.service.d/override.conf

sudo yum install -y docker-engine-1.11.2
sudo yum install -y docker-engine-selinux-1.11.2
sudo yum install -y chrony
sudo yum install -y java-1.8.0-openjdk.x86_64
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
sudo python get-pip.py
sudo pip install virtualenv
sudo service docker start