
provider "aws" {
  region = "${var.aws_region}"
}

provider "docker" {
  host = "tcp://${aws_instance.web.public_ip}:2376/"
}

resource "aws_vpc" "default" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags {
    Name = "website-vpc"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags {
    Name = "Public Subnet"
  }
}

resource "aws_security_group" "allow_web" {
  name = "allow_http"
  description = "Allow http and ssh inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

resource "aws_instance" "web" {
  ami           = "${var.aws_ami}"
  instance_type = "${var.aws_type}"
  count = "1"
  associate_public_ip_address = "true"

  //security_groups = [
  //    "${aws_security_group.allow-ssh.name}",
  //    "${aws_security_group.allow-docker.name}",
  //    "${aws_security_group.allow-all-http-https.name}",
  //]

  key_name = "${aws_key_pair.auth.id}"
  vpc_security_group_ids = ["${aws_security_group.allow_web.id}"]
  subnet_id = "${aws_subnet.default.id}"

  tags {
    Name = "Web"
    Product = "Docker Nginx and Node"
  }

  provisioner "file" {
    source      = "./app"
    destination = "/home/ec2-user/app"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "file" {
    source      = "./nginx"
    destination = "/home/ec2-user/nginx"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/ec2-user/docker-compose.yml"
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum -y update",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.15.0/docker-compose-`uname -s`-`uname -m` > docker-compose",
      "sudo mv docker-compose /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo /usr/local/bin/docker-compose up -d --scale web=2",
    ],
    connection {
      type     = "ssh"
      user     = "ec2-user"
      private_key = "${file(var.private_key_path)}"
    }
  }
}

//module "docker" {
//  source = "./docker"
//  aws_ip = "${module.aws.public_ip}"
//}