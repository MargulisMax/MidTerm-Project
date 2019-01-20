provider "aws" {
  shared_credentials_file = "~/.aws/credentials"
  region = "${var.region}"
}
resource "tls_private_key" "new_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "aws_key_pair" "public_key" {
  key_name   = "${var.gen_key}"
  public_key = "${tls_private_key.new_key.public_key_openssh}"
}
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr-vpc}"
  tags {
    Name = "MTP-VPC"
  }
}
resource "aws_subnet" "subnet-servers" {
  cidr_block = "${var.cidr-subnet-servers}"
  map_public_ip_on_launch = true
  availability_zone = "${var.azone}"
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "MTP-Servers_Subnet"
  }
}
resource "aws_internet_gateway" "igw" {
 vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "MTP-IGW"
  }
}
resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "${var.all-ip-range}"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
  tags {
    Name = "MTP-Route_Table"
  }
}
resource "aws_route_table_association" "route-table-association" {
  route_table_id = "${aws_route_table.route-table.id}"
  subnet_id = "${aws_subnet.subnet-servers.id}"
}
resource "aws_security_group" "security-group" {
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 8500
    protocol = "tcp"
    to_port = 8500
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 8600
    protocol = "tcp"
    to_port = 8600
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 8300
    protocol = "tcp"
    to_port = 8303
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 9200
    protocol = "tcp"
    to_port = 9200
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 9300
    protocol = "tcp"
    to_port = 9300
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 5044
    protocol = "tcp"
    to_port = 5044
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 5601
    protocol = "tcp"
    to_port = 5601
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 9090
    protocol = "tcp"
    to_port = 9090
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 3000
    protocol = "tcp"
    to_port = 3000
    cidr_blocks = ["${var.all-ip-range}"]
  }
  ingress {
    from_port = 22
    protocol = "tcp"
    to_port = 22
    cidr_blocks = ["${var.all-ip-range}"]
  }
  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = ["${var.all-ip-range}"]
  }
  tags {
    Name = "MTP-Security_Group"
  }
}

resource "aws_iam_policy" "Describe-Instances" {
  name = "Describe-Instances"
  policy = "${var.IAM-Policy}"
}

resource "aws_iam_role" "Discover-Consul" {
  name = "Discover-Consul"
  assume_role_policy = "${var.IAM-Role}"
}

resource "aws_iam_role_policy_attachment" "Bind-Role-To-Pol" {
  policy_arn = "${aws_iam_policy.Describe-Instances.arn}"
  role = "${aws_iam_role.Discover-Consul.name}"
}

resource "aws_iam_instance_profile" "Consul-Profile" {
  name = "Consul-Profile"
  role = "${aws_iam_role.Discover-Consul.name}"
}

resource "aws_instance" "Consul" {
  count = 1
  ami = "${var.aws-ami}"
  instance_type = "${var.aws-ami-type-t2}"
  availability_zone = "${var.azone}"
  subnet_id = "${aws_subnet.subnet-servers.id}"
  security_groups = ["${aws_security_group.security-group.id}"]
  key_name = "${var.gen_key}"
  iam_instance_profile = "${aws_iam_instance_profile.Consul-Profile.name}"
  root_block_device {
    volume_type = "standard"
    volume_size = "10"
    delete_on_termination = "true"
  }
  user_data = "${file("./bootstrap/consul.sh")}"
  tags {
    Name = "MTP-Consul"
  }
  depends_on = ["aws_subnet.subnet-servers"]
}

resource "aws_instance" "EStack" {
  count = 1
  ami = "${var.aws-ami}"
  instance_type = "${var.aws-ami-type-t3}"
  availability_zone = "${var.azone}"
  subnet_id = "${aws_subnet.subnet-servers.id}"
  security_groups = ["${aws_security_group.security-group.id}"]
  key_name = "${var.gen_key}"
  iam_instance_profile = "${aws_iam_instance_profile.Consul-Profile.name}"
  root_block_device {
    volume_type = "standard"
    volume_size = "10"
    delete_on_termination = "true"
  }
  user_data = "${file("./bootstrap/estack.sh")}"
  tags {
    Name = "MTP-EStack"
  }
  depends_on = ["aws_instance.Consul"]
}

resource "aws_instance" "DummyAPP01" {
  count = 1
  ami = "${var.aws-ami}"
  instance_type = "${var.aws-ami-type-t2}"
  availability_zone = "${var.azone}"
  subnet_id = "${aws_subnet.subnet-servers.id}"
  security_groups = ["${aws_security_group.security-group.id}"]
  key_name = "${var.gen_key}"
  iam_instance_profile = "${aws_iam_instance_profile.Consul-Profile.name}"
  root_block_device {
    volume_type = "standard"
    volume_size = "10"
    delete_on_termination = "true"
  }
  user_data = "${file("./bootstrap/dummyapp01.sh")}"
  tags {
    Name = "MTP-DummyAPP01"
  }
  depends_on = ["aws_instance.Consul", "aws_instance.EStack"]
}

resource "aws_instance" "DummyAPP02" {
  count = 1
  ami = "${var.aws-ami}"
  instance_type = "${var.aws-ami-type-t2}"
  availability_zone = "${var.azone}"
  subnet_id = "${aws_subnet.subnet-servers.id}"
  security_groups = ["${aws_security_group.security-group.id}"]
  key_name = "${var.gen_key}"
  iam_instance_profile = "${aws_iam_instance_profile.Consul-Profile.name}"
  root_block_device {
    volume_type = "standard"
    volume_size = "10"
    delete_on_termination = "true"
  }
  user_data = "${file("./bootstrap/dummyapp02.sh")}"
  tags {
    Name = "MTP-DummyAPP02"
  }
  depends_on = ["aws_instance.Consul", "aws_instance.EStack"]
}

resource "aws_instance" "Prometheus" {
  count = 1
  ami = "${var.aws-ami}"
  instance_type = "${var.aws-ami-type-t2}"
  availability_zone = "${var.azone}"
  subnet_id = "${aws_subnet.subnet-servers.id}"
  security_groups = ["${aws_security_group.security-group.id}"]
  key_name = "${var.gen_key}"
  iam_instance_profile = "${aws_iam_instance_profile.Consul-Profile.name}"
  root_block_device {
    volume_type = "standard"
    volume_size = "10"
    delete_on_termination = "true"
  }
  user_data = "${file("./bootstrap/prometheus.sh")}"
  tags {
    Name = "MTP-Prometheus"
  }
  depends_on = ["aws_instance.Consul", "aws_instance.EStack", "aws_instance.DummyAPP01", "aws_instance.DummyAPP02"]
}

resource "aws_instance" "Grafana" {
  count = 1
  ami = "${var.aws-ami}"
  instance_type = "${var.aws-ami-type-t2}"
  availability_zone = "${var.azone}"
  subnet_id = "${aws_subnet.subnet-servers.id}"
  security_groups = ["${aws_security_group.security-group.id}"]
  key_name = "${var.gen_key}"
  iam_instance_profile = "${aws_iam_instance_profile.Consul-Profile.name}"
  root_block_device {
    volume_type = "standard"
    volume_size = "10"
    delete_on_termination = "true"
  }
  user_data = "${file("./bootstrap/grafana.sh")}"
  tags {
    Name = "MTP-Grafana"
  }
  depends_on = ["aws_instance.Prometheus"]
}

output "Consul_PIP" {
  value = "${aws_instance.Consul.public_ip}"
}

output "Kibana_PIP" {
  value = "${aws_instance.EStack.public_ip}"
}

output "Prometheus_PIP" {
  value = "${aws_instance.Prometheus.public_ip}"
}

output "Grafana_PIP" {
  value = "${aws_instance.Grafana.public_ip}"
}
