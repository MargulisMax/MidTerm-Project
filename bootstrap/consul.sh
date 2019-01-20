#!/bin/bash
sudo yum update -y
sudo yum install dnsmasq -y
sudo sed -i 's/.*nameserver.*/nameserver 127.0.0.1\n&/' /etc/resolv.conf
sudo touch /etc/dnsmasq.d/10-consul
echo "server=/consul/127.0.0.1#8600" | sudo tee /etc/dnsmasq.d/10-consul
sudo systemctl start dnsmasq
cd /tmp/
wget https://releases.hashicorp.com/consul/1.4.0/consul_1.4.0_linux_amd64.zip
sudo unzip consul_1.4.0_linux_amd64.zip
sudo rm consul_1.4.0_linux_amd64.zip
sudo mv consul /usr/bin/
sudo mkdir /etc/consul.d
sudo mkdir /var/lib/consul
sudo consul agent -server -bootstrap-expect 1 -ui -client=0.0.0.0 -bind=0.0.0.0 -node Consul-Server -log-file=/var/log/ -data-dir /var/lib/consul -config-dir /etc/consul.d &
sudo touch /etc/yum.repos.d/elastic-stack.repo
cat <<EOL | sudo tee /etc/yum.repos.d/elastic-stack.repo
[elasticsearch-6.x]
name=Elasticsearch repository for 6.x packages
baseurl=https://artifacts.elastic.co/packages/6.x/yum
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
enabled=1
autorefresh=1
type=rpm-md
EOL
sudo yum install filebeat -y
cd /tmp/
sudo wget https://raw.githubusercontent.com/MargulisMax/MidTerm-Project/master/filebeat.yml
sudo mv -f filebeat.yml /etc/filebeat/
aws_tag=$(aws ec2 describe-tags --region us-east-1 --filter "Name=resource-id,Values=$(ec2-metadata -i | cut -d ' ' -f2)" | grep -i value | cut -d '"' -f4)
echo "name: $aws_tag" | sudo tee -a /etc/filebeat/filebeat.yml
sudo systemctl enable filebeat
sudo systemctl start filebeat