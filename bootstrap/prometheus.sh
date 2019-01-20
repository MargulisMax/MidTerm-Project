#!/bin/bash
sudo yum update -y
sudo yum install dnsmasq -y
sudo sed -i 's/.*nameserver.*/nameserver 127.0.0.1\n&/' /etc/resolv.conf
sudo touch /etc/dnsmasq.d/10-consul
echo "server=/consul/127.0.0.1#8600" | sudo tee /etc/dnsmasq.d/10-consul
sudo systemctl start dnsmasq
cd /tmp
sudo wget https://releases.hashicorp.com/consul/1.4.0/consul_1.4.0_linux_amd64.zip
sudo wget https://github.com/prometheus/prometheus/releases/download/v2.6.0/prometheus-2.6.0.linux-amd64.tar.gz
sudo wget https://raw.githubusercontent.com/MargulisMax/MidTerm-Project/master/prometheus.yml
sudo unzip consul_1.4.0_linux_amd64.zip
sudo rm -f consul_1.4.0_linux_amd64.zip
sudo mv consul /usr/bin/
sudo mkdir /etc/consul.d
sudo mkdir /var/lib/consul
sudo consul agent -bind `hostname -i` -data-dir /var/lib/consul -config-dir /etc/consul.d -node=Prometheus -retry-join "provider=aws tag_key=Name tag_value=MTP-Consul" &
sudo tar -xzvf prometheus-2.6.0.linux-amd64.tar.gz
sudo rm *.tar.gz
sudo mkdir /opt/prometheus
sudo mv prometheus-2.6.0.linux-amd64/* /opt/prometheus/
sudo mv -f prometheus.yml /opt/prometheus/
sudo mkdir /opt/prometheus/data
sudo useradd prometheus
sudo chown -R prometheus:prometheus /opt/prometheus/
sudo touch /etc/systemd/system/prometheus.service
cat <<EOL | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Server
Documentation=https://prometheus.io/docs/introduction/overview/
After=network-online.target
[Service]
User=prometheus
Restart=on-failure
ExecStart=/opt/prometheus/prometheus \
--config.file=/opt/prometheus/prometheus.yml \
--storage.tsdb.path=/opt/prometheus/data
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl start prometheus
sudo systemctl enable prometheus
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