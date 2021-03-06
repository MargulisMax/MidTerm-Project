#!/bin/bash
sudo yum update -y
sudo yum install java-1.8.0-openjdk -y
sudo yum install dnsmasq -y
sudo sed -i 's/.*nameserver.*/nameserver 127.0.0.1\n&/' /etc/resolv.conf
sudo touch /etc/dnsmasq.d/10-consul
echo "server=/consul/127.0.0.1#8600" | sudo tee /etc/dnsmasq.d/10-consul
sudo systemctl start dnsmasq
cd /tmp
sudo wget https://releases.hashicorp.com/consul/1.4.0/consul_1.4.0_linux_amd64.zip
sudo unzip consul_1.4.0_linux_amd64.zip
sudo rm -f consul_1.4.0_linux_amd64.zip
sudo mv consul /usr/bin/
sudo mkdir /etc/consul.d
sudo mkdir /var/lib/consul
sudo consul agent -bind `ec2-metadata -o| cut -d " " -f2` -data-dir /var/lib/consul -config-dir /etc/consul.d -node=ELK -retry-join "provider=aws tag_key=Name tag_value=MTP-Consul" &
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
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
sudo yum install elasticsearch -y
sudo yum install kibana -y
sudo yum install logstash -y
sudo yum install filebeat -y
sudo sed -i 's/.*server.host: "localhost".*/server.host: "0.0.0.0"\n&/' /etc/kibana/kibana.yml
cd /etc/logstash/conf.d/
sudo wget https://raw.githubusercontent.com/MargulisMax/MidTerm-Project/master/01-logstash.conf
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
sudo systemctl enable logstash
sudo systemctl start logstash
sudo systemctl enable kibana
sudo systemctl start kibana
cd /tmp/
sudo wget https://raw.githubusercontent.com/MargulisMax/MidTerm-Project/master/filebeat.yml
sudo mv -f filebeat.yml /etc/filebeat/
aws_tag=$(aws ec2 describe-tags --region us-east-1 --filter "Name=resource-id,Values=$(ec2-metadata -i | cut -d ' ' -f2)" | grep -i value | cut -d '"' -f4)
echo "name: $aws_tag" | sudo tee -a /etc/filebeat/filebeat.yml
sudo systemctl enable filebeat
sudo systemctl start filebeat