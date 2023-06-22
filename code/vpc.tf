# create VPC Virtual Private Cloud

resource "aws_vpc" "vpc" {
  cidr_block                       = "10.0.0.0/16"
  instance_tenancy                 = "default"
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true
  tags = {
    Name = "${var.common_tags}VPC"
  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.common_tags}IGW"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.aws-availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.common_tags}PublicSubnet"
  }
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name = "${var.common_tags}PublicRT"
  }
}

resource "aws_route_table_association" "public-subnet-route-table-association" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_subnet" "private-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = var.aws-availability_zone
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.common_tags}PrivateSubnet"
  }

}


resource "aws_security_group" "public-security-group" {
  name        = "${var.common_tags}-security-group"
  description = "Allow inbound SSH and HTTP traffic"

  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "TfKey" {
  key_name   = "TfKey"
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "local_file" "TfKey" {
  content  = tls_private_key.rsa.private_key_pem
  filename = "TfKey"
}

resource "aws_instance" "app_server" {
  ami                         = "ami-053b0d53c279acc90"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public-subnet.id
  vpc_security_group_ids      = [aws_security_group.public-security-group.id]
  associate_public_ip_address = true
  key_name                    = "TfKey"
  tags = {
    Name = "${var.common_tags}-demo"
  }
}


