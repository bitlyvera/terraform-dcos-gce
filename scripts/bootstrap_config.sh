#!/bin/bash -e

CLUSTER_NAME=`curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/clustername"`
MASTER_IP=`curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/master_ip"`
MASTER_IPS=`curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/master_ips"`
SLAVE_IPS=`curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/slave_ips"`
SSH_USER=`curl -H "Metadata-Flavor: Google" "http://metadata.google.internal/computeMetadata/v1/instance/attributes/user"`

curl -O https://downloads.dcos.io/dcos/stable/dcos_generate_config.sh
curl -O https://downloads.dcos.io/binaries/cli/linux/x86-64/dcos-1.8/dcos
chmod +x dcos
sudo mv dcos /usr/bin/
dcos config set core.dcos_url http://$MASTER_IP 

mkdir -p genconf
cp -f ssh_key genconf/ssh_key
chmod o-r genconf/ssh_key
chmod g-r genconf/ssh_key
chmod u+x genconf/ssh_key
tee genconf/ip-detect <<EOF
#!/bin/sh
curl -fsSL -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/network-interfaces/0/ip
EOF

tee genconf/config.yaml <<EOF
agent_list:
- $SLAVE_IPS
# Use this bootstrap_url value unless you have moved the DC/OS installer assets.
bootstrap_url: file:///opt/dcos_install_tmp
cluster_name: $CLUSTER_NAME 
exhibitor_storage_backend: static
master_discovery: static
master_list:
- $MASTER_IPS 
resolvers:
- 8.8.4.4
- 8.8.8.8
ssh_port: 22
ssh_user: $SSH_USER
EOF

sudo bash dcos_generate_config.sh --genconf &&
sudo bash dcos_generate_config.sh --install-prereqs -v &&
sudo bash dcos_generate_config.sh --preflight -v  &&
sudo bash -x dcos_generate_config.sh --deploy -v || true
sudo bash -x dcos_generate_config.sh --postflight -v || true