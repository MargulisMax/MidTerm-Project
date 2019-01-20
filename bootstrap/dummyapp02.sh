#!/bin/bash
sudo yum update -y
sudo yum install dnsmasq -y
sudo sed -i 's/.*nameserver.*/nameserver 127.0.0.1\n&/' /etc/resolv.conf
sudo touch /etc/dnsmasq.d/10-consul
echo "server=/consul/127.0.0.1#8600" | sudo tee /etc/dnsmasq.d/10-consul
sudo systemctl start dnsmasq
sudo yum install -y yum-utils device-mapper-persistent-data lvm2 policycoreutils-python
cd /tmp
sudo wget http://vault.centos.org/centos/7.3.1611/extras/x86_64/Packages/container-selinux-2.19-2.1.el7.noarch.rpm
sudo rpm -ivh container-selinux-2.19-2.1.el7.noarch.rpm
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install docker-ce -y
sudo systemctl start docker
sudo mkdir /opt/docker && cd /opt/docker
sudo wget https://raw.githubusercontent.com/MargulisMax/MidTerm-Project/master/Dockerfile
sudo docker build -t dummyapp .
sudo docker run -d -p 80:65433/tcp dummyapp
cd /tmp/
sudo wget https://releases.hashicorp.com/consul/1.4.0/consul_1.4.0_linux_amd64.zip
sudo wget https://raw.githubusercontent.com/MargulisMax/MidTerm-Project/master/web.json
sudo unzip consul_1.4.0_linux_amd64.zip
sudo rm -f *.zip
sudo mv consul /usr/bin/
sudo mkdir /etc/consul.d
sudo mkdir /var/lib/consul
sudo mv web.json /etc/consul.d/
sudo consul agent -bind `hostname -i` -data-dir /var/lib/consul -config-dir /etc/consul.d -node=DummyNode2 -retry-join "provider=aws tag_key=Name tag_value=MTP-Consul" &
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