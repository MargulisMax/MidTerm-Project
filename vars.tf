variable "gen_key" {
  default = "temp_key"
}
variable "region" {
  default = "us-east-1"
}
variable "azone" {
  default = "us-east-1a"
}
variable "cidr-vpc" {
  default = "10.10.10.0/24"
}
variable "cidr-subnet-servers" {
  default = "10.10.10.0/27"
}
variable "all-ip-range" {
  default = "0.0.0.0/0"
}
variable "aws-ami" {
  description = "Amazon Linux 2 - x64"
  default = "ami-035be7bafff33b6b6"
}
variable "aws-ami-type-t2" {
  default = "t2.micro"
}
variable "aws-ami-type-t3" {
  default = "t3.medium"
}
variable "IAM-Policy" {
  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:Describe*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
variable "IAM-Role" {
  default = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}