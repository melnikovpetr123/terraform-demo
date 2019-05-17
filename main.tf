provider "aws" {
  access_key  = "${var.access_key}"
  secret_key  = "${var.secret_key}"
  region      = "${var.region}"
}

resource "tls_private_key" "priv-key" {
  algorithm   = "RSA" 
}

resource "aws_key_pair" "generated_key" {
  key_name   = "my-key"
  public_key = "${tls_private_key.priv-key.public_key_openssh}"
}

resource "tls_private_key" "ssl" {
  algorithm   = "RSA"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "tf-example"
  }
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = "${aws_vpc.my_vpc.id}"
  cidr_block        = "10.0.2.0/24"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_internet_gateway" "my_gw" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  tags {
    Name = "VPC IGW"
  }
}


resource "aws_route_table" "web-public-rt" {
  vpc_id = "${aws_vpc.my_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.my_gw.id}"
  }

  tags {
    Name = "Public Subnet RT"
  }
}

resource "aws_route_table_association" "web-public-rt" {
  subnet_id = "${aws_subnet.my_subnet.id}"
  route_table_id = "${aws_route_table.web-public-rt.id}"
}


resource "aws_instance" "master" {
  ami           = "ami-03bca18cb3dc173c9"
  instance_type = "t2.micro"
  subnet_id   = "${aws_subnet.my_subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.f-wall.id}"]
  associate_public_ip_address = true
  key_name = "my-key"
  connection {
    user = "ubuntu"
    private_key = "${tls_private_key.priv-key.private_key_pem}"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y python python-pip --no-install-recommends",
      "sudo pip install --upgrade setuptools && sudo pip install --upgrade docker-py",
      "echo --------------------SUCCESS!!!"
    ]
  }
  tags = { 
    Name = "PetrMelnikov-demo"
  }
}


resource "tls_self_signed_cert" "crt" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.ssl.private_key_pem}"

  subject {
    common_name  = "${aws_instance.master.public_dns}"
    organization = "Examples, Inc"
  }

  validity_period_hours = 12000

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}


resource "null_resource" "run_sed" {
  provisioner "local-exec" {
    command = "cp nginx.conf_orig nginx.conf && sed -i 's/WHAT_TO_PROXY/${var.what_to_proxy}/g' nginx.conf"
  }
  triggers = {
      track_var = "${var.what_to_proxy}"
  }
}



output "master.ip" {
  value = "${aws_instance.master.public_ip}"
}
output "master.public_dns" {
 value = "${aws_instance.master.public_dns}"
}

resource "local_file" "pem-file" {
    content     = "${tls_private_key.priv-key.private_key_pem}"
    filename = "my-key-private.pem"

  provisioner "local-exec" {
      command = "chmod 600 my-key-private.pem"
  }
}

resource "local_file" "crt-file" {
    content     = "${tls_self_signed_cert.crt.cert_pem}"
    filename = "cert-pem.crt"
}

resource "local_file" "ssl" {
    content     = "${tls_private_key.ssl.private_key_pem}"
    filename = "ssl-priv-key.pem"
}
