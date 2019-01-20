# MidTerm-Project Deployment Procedure

Reminder: please make sure that "~/.aws/credentials" are set correctly.

To deploy the environment run:
```
git clone https://github.com/MargulisMax/MidTerm-Project.git
cd MidTerm-Project
terraform init
terraform apply --auto-approve
```

To check the environment do the following:
```
Note! Public-IP will be outputed by Terraform on successfull deployment.

Consul: http://Consul_PIP:8500
Kibana: http://Grafana_PIP:5601
Prometheus: http://Kibana_PIP:9090
Grafana: http://Prometheus_PIP:3000
```